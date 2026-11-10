import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType } from '@prisma/client';
import { isEmail } from 'class-validator';
import { AuditActions, AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * The only things this page can read or change. Passwords and keys are not here on
 * purpose, and nothing outside this list is ever returned.
 */
export const APP_SETTINGS = [
  { key: 'appName', group: 'General', label: 'App name', env: 'APP_NAME', fallback: 'SurveyScriber', hint: 'Used in the wording of emails.' },
  { key: 'senderName', group: 'General', label: 'Email sender name', env: '', fallback: '', hint: 'The name emails come from. Empty means the app name.' },
  { key: 'supportEmail', group: 'General', label: 'Support email', env: '', fallback: '', type: 'email', hint: 'Replies to emails go here. Empty means replies go to the sending address.' },
  { key: 'publicUrl', group: 'General', label: 'Public address of the server', env: 'PUBLIC_API_URL', fallback: 'https://portal.surveyscriber.com', hint: 'Account activation links in emails start with this address.' },
  { key: 'companyName', group: 'Company, on invoices', label: 'Company name', env: 'COMPANY_NAME', fallback: 'SurveyScriber Ltd' },
  { key: 'companyAddress1', group: 'Company, on invoices', label: 'Address line 1', env: 'COMPANY_ADDRESS_LINE1', fallback: '123 Business Park' },
  { key: 'companyAddress2', group: 'Company, on invoices', label: 'Address line 2', env: 'COMPANY_ADDRESS_LINE2', fallback: 'London, SW1A 1AA' },
  { key: 'companyVat', group: 'Company, on invoices', label: 'VAT number', env: 'COMPANY_VAT_NUMBER', fallback: '' },
  { key: 'companyEmail', group: 'Company, on invoices', label: 'Email', env: 'COMPANY_EMAIL', fallback: 'billing@surveyscriber.com', type: 'email' },
  { key: 'companyPhone', group: 'Company, on invoices', label: 'Phone', env: 'COMPANY_PHONE', fallback: '' },
  { key: 'bankAccountName', group: 'Bank details, on unpaid invoices', label: 'Account name', env: 'BANK_ACCOUNT_NAME', fallback: 'SurveyScriber Ltd' },
  { key: 'bankSortCode', group: 'Bank details, on unpaid invoices', label: 'Sort code', env: 'BANK_SORT_CODE', fallback: '' },
  { key: 'bankAccountNumber', group: 'Bank details, on unpaid invoices', label: 'Account number', env: 'BANK_ACCOUNT_NUMBER', fallback: '', hint: 'Bank details print only when this is filled in.' },
] as const;

export type AppSettingKey = (typeof APP_SETTINGS)[number]['key'];
export type AppSettingValues = Record<AppSettingKey, string>;

const MAX_LENGTH = 200;

interface Actor {
  id: string;
}

@Injectable()
export class AppSettingsService {
  private readonly logger = new Logger(AppSettingsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly audit: AuditService,
  ) {}

  private serverValue(setting: (typeof APP_SETTINGS)[number]): string {
    return (setting.env && this.configService.get<string>(setting.env)) || setting.fallback;
  }

  /** The value of every setting right now. Read fresh each time, so no restart is needed. */
  async values(): Promise<AppSettingValues> {
    let stored = new Map<string, string>();
    try {
      const rows = await this.prisma.appSetting.findMany();
      stored = new Map(rows.map((r) => [r.key, r.value]));
    } catch (error) {
      // An email or invoice must not fail because of this: the server's own values still work.
      this.logger.warn(`Could not read settings, using the server's values: ${error}`);
    }
    const values = Object.fromEntries(
      APP_SETTINGS.map((s) => [s.key, stored.get(s.key) ?? this.serverValue(s)]),
    ) as AppSettingValues;
    values.senderName = values.senderName || values.appName;
    return values;
  }

  async list() {
    const rows = await this.prisma.appSetting.findMany();
    const stored = new Map(rows.map((r) => [r.key, r]));
    return APP_SETTINGS.map((s) => {
      const row = stored.get(s.key);
      return {
        key: s.key,
        group: s.group,
        label: s.label,
        type: 'type' in s ? s.type : 'text',
        hint: 'hint' in s ? s.hint : null,
        value: row?.value ?? '',
        serverValue: this.serverValue(s),
        updatedAt: row?.updatedAt ?? null,
        updatedBy: row?.updatedBy ?? null,
      };
    });
  }

  /** An empty value removes the setting, so the server's own value is used again. */
  async update(values: Record<string, unknown>, actor: Actor & { email: string }) {
    const known = new Map<string, (typeof APP_SETTINGS)[number]>(APP_SETTINGS.map((s) => [s.key, s]));
    const clean: [string, string][] = [];
    for (const [key, raw] of Object.entries(values)) {
      const setting = known.get(key);
      if (!setting) throw new BadRequestException(`"${key}" is not a setting that can be changed here.`);
      if (typeof raw !== 'string') throw new BadRequestException(`${setting.label} must be text.`);
      const value = raw.trim();
      if (value.length > MAX_LENGTH) throw new BadRequestException(`${setting.label} is too long.`);
      if (value && 'type' in setting && setting.type === 'email' && !isEmail(value)) {
        throw new BadRequestException(`${setting.label} is not a valid email address.`);
      }
      clean.push([key, value]);
    }

    const before = new Map((await this.prisma.appSetting.findMany()).map((r) => [r.key, r.value]));
    const changed = clean.filter(([key, value]) => (before.get(key) ?? '') !== value);
    await this.prisma.$transaction(
      changed.map(([key, value]) =>
        value
          ? this.prisma.appSetting.upsert({
              where: { key },
              create: { key, value, updatedBy: actor.email },
              update: { value, updatedBy: actor.email },
            })
          : this.prisma.appSetting.deleteMany({ where: { key } }),
      ),
    );
    if (changed.length) {
      await this.audit.log({
        actorType: ActorType.STAFF,
        actorId: actor.id,
        action: AuditActions.APP_SETTINGS_UPDATED,
        entityType: AuditEntityType.AUTH,
        // Names only: the audit log has no need of bank details.
        metadata: { settings: changed.map(([key]) => key) },
      });
    }
    return this.list();
  }
}
