import { BadRequestException, Injectable, Logger, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { ActorType, AuditEntityType } from '@prisma/client';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { AuditActions, AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { EMAIL_TEMPLATE_DEFAULTS, EmailTemplateDefault } from './email-template.defaults';
import { EmailContent, fillTemplate, problemWith, SAMPLE_RAW_HTML, SAMPLE_VALUES } from './email-template.helpers';

interface Actor {
  id: string;
  email: string;
}

@Injectable()
export class EmailTemplatesService {
  private readonly logger = new Logger(EmailTemplatesService.name);
  private readonly byKey = new Map(EMAIL_TEMPLATE_DEFAULTS.map((t) => [t.key, t]));

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly audit: AuditService,
    private readonly settings: AppSettingsService,
  ) {}

  private async commonValues(): Promise<Record<string, string>> {
    const { appName } = await this.settings.values();
    return { appName, year: String(new Date().getFullYear()) };
  }

  /** The server's public address, without a trailing slash: links in emails start with it. */
  async publicUrl(): Promise<string> {
    const { publicUrl } = await this.settings.values();
    return publicUrl.replace(/\/+$/, '');
  }

  /** Where Contact Us messages go: the support email, else the company email. */
  async supportAddress(): Promise<string> {
    const { supportEmail, companyEmail } = await this.settings.values();
    return supportEmail || companyEmail;
  }

  /** Who an email comes from, and where replies go. The address itself stays the server's. */
  async sender(address: string): Promise<{ from: { name: string; address: string }; replyTo?: string }> {
    const { senderName, supportEmail } = await this.settings.values();
    return { from: { name: senderName, address }, ...(supportEmail ? { replyTo: supportEmail } : {}) };
  }

  /**
   * The email to send. An edited template is used when it can be read and is still
   * sound; otherwise the original goes out, because an email must never be lost to this.
   */
  async render(
    key: string,
    values: Record<string, string>,
    rawHtml: Record<string, string> = {},
  ): Promise<EmailContent> {
    const original = this.originalOf(key);
    let template: EmailContent = original;
    try {
      const stored = await this.prisma.emailTemplate.findUnique({ where: { key } });
      if (stored) {
        const problem = problemWith(stored, original);
        if (problem) this.logger.warn(`Edited email "${key}" ignored: ${problem}`);
        else template = stored;
      }
    } catch (error) {
      this.logger.warn(`Could not read the edited email "${key}", sending the original: ${error}`);
    }
    return fillTemplate(template, { ...(await this.commonValues()), ...values }, rawHtml);
  }

  async list() {
    const stored = await this.prisma.emailTemplate.findMany();
    const edits = new Map(stored.map((s) => [s.key, s]));
    return EMAIL_TEMPLATE_DEFAULTS.map((t) => ({
      key: t.key,
      name: t.name,
      audience: t.audience,
      edited: edits.has(t.key),
      updatedAt: edits.get(t.key)?.updatedAt ?? null,
      updatedBy: edits.get(t.key)?.updatedBy ?? null,
    }));
  }

  async get(key: string) {
    const original = this.originalOf(key);
    const stored = await this.prisma.emailTemplate.findUnique({ where: { key } });
    return {
      key,
      name: original.name,
      audience: original.audience,
      placeholders: original.placeholders,
      edited: !!stored,
      updatedAt: stored?.updatedAt ?? null,
      updatedBy: stored?.updatedBy ?? null,
      subject: stored?.subject ?? original.subject,
      html: stored?.html ?? original.html,
      text: stored?.text ?? original.text,
      original: { subject: original.subject, html: original.html, text: original.text },
    };
  }

  async save(key: string, edit: EmailContent, actor: Actor) {
    const original = this.originalOf(key);
    this.assertSound(edit, original);
    const data = { subject: edit.subject, html: edit.html, text: edit.text, updatedBy: actor.email };
    await this.prisma.emailTemplate.upsert({ where: { key }, create: { key, ...data }, update: data });
    await this.record(actor, AuditActions.EMAIL_TEMPLATE_UPDATED, key);
    return this.get(key);
  }

  async reset(key: string, actor: Actor) {
    this.originalOf(key);
    await this.prisma.emailTemplate.deleteMany({ where: { key } });
    await this.record(actor, AuditActions.EMAIL_TEMPLATE_RESET, key);
    return this.get(key);
  }

  async preview(key: string, edit: EmailContent): Promise<EmailContent> {
    const original = this.originalOf(key);
    this.assertSound(edit, original);
    return fillTemplate(edit, { ...(await this.commonValues()), ...SAMPLE_VALUES }, SAMPLE_RAW_HTML);
  }

  /** Goes only to the person asking, so this can never be used to send mail to anyone else. */
  async sendTest(key: string, edit: EmailContent, actor: Actor): Promise<{ sentTo: string }> {
    const content = await this.preview(key, edit);
    const transporter = this.createTransporter();
    if (!transporter) {
      throw new ServiceUnavailableException('This server has no email account set up, so nothing could be sent.');
    }
    const from = this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    try {
      await transporter.sendMail({
        ...(await this.sender(from)),
        to: actor.email,
        subject: `[Test] ${content.subject}`,
        html: content.html,
        text: content.text,
      });
    } catch (error) {
      this.logger.error(`Test email "${key}" failed: ${error}`);
      throw new ServiceUnavailableException('The email server refused the test email. Please try again.');
    }
    await this.record(actor, AuditActions.EMAIL_TEMPLATE_TEST_SENT, key);
    return { sentTo: actor.email };
  }

  private createTransporter(): nodemailer.Transporter | null {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    if (!host || !user || !pass) return null;
    return nodemailer.createTransport({
      host,
      port: parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10),
      secure: this.configService.get<string>('SMTP_SECURE') === 'true',
      auth: { user, pass },
    });
  }

  private originalOf(key: string): EmailTemplateDefault {
    const original = this.byKey.get(key);
    if (!original) throw new NotFoundException(`There is no email called "${key}"`);
    return original;
  }

  private assertSound(edit: EmailContent, original: EmailTemplateDefault): void {
    const problem = problemWith(edit, original);
    if (problem) throw new BadRequestException(problem);
  }

  private async record(actor: Actor, action: string, key: string): Promise<void> {
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: actor.id,
      action,
      entityType: AuditEntityType.AUTH,
      metadata: { emailTemplate: key },
    });
  }
}
