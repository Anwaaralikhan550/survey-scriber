import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InvoicePdfService } from '../invoices/invoice-pdf.service';
import { APP_SETTINGS, AppSettingsService } from './app-settings.service';

const env: Record<string, string> = { APP_NAME: 'From Env', COMPANY_NAME: 'Env Co', SMTP_PASS: 'secret-password', JWT_SECRET: 'secret-jwt' };
const config = { get: (key: string) => env[key] } as unknown as ConfigService;
const actor = { id: 'admin', email: 'boss@example.com' };

function setup(initial: Record<string, string> = {}) {
  const rows = new Map(Object.entries(initial));
  const prisma = {
    appSetting: {
      findMany: jest.fn(async () => [...rows].map(([key, value]) => ({ key, value, updatedAt: new Date(), updatedBy: 'x' }))),
      upsert: jest.fn(({ where, create }: any) => { rows.set(where.key, create.value); return Promise.resolve(); }),
      deleteMany: jest.fn(({ where }: any) => { rows.delete(where.key); return Promise.resolve(); }),
    },
    $transaction: jest.fn(async (ops: Promise<unknown>[]) => Promise.all(ops)),
  };
  const audit = { log: jest.fn(async () => undefined) };
  return { prisma, audit, rows, settings: new AppSettingsService(prisma as never, config, audit as never) };
}

describe('AppSettingsService', () => {
  it('with nothing saved, the server values are used', async () => {
    const { settings } = setup();
    const v = await settings.values();
    expect(v.appName).toBe('From Env');
    expect(v.companyName).toBe('Env Co');
    expect(v.companyAddress1).toBe('123 Business Park');
    expect(v.bankAccountNumber).toBe('');
  });

  it('a saved value wins, read fresh every time, with no restart', async () => {
    const { settings } = setup();
    await settings.update({ companyName: 'New Co' }, actor);
    expect((await settings.values()).companyName).toBe('New Co');
  });

  it('emptying a setting goes back to the server value', async () => {
    const { settings, rows } = setup({ companyName: 'New Co' });
    await settings.update({ companyName: '  ' }, actor);
    expect(rows.has('companyName')).toBe(false);
    expect((await settings.values()).companyName).toBe('Env Co');
  });

  it('the sender name follows the app name until it has its own', async () => {
    const { settings } = setup({ appName: 'Acme' });
    expect((await settings.values()).senderName).toBe('Acme');
    await settings.update({ senderName: 'Acme Office' }, actor);
    expect((await settings.values()).senderName).toBe('Acme Office');
  });

  it('if the database cannot answer, the server values still work', async () => {
    const { settings, prisma } = setup({ companyName: 'New Co' });
    prisma.appSetting.findMany.mockRejectedValue(new Error('down'));
    expect((await settings.values()).companyName).toBe('Env Co');
  });

  it.each([
    ['a bad support email', { supportEmail: 'not-an-email' }, /valid email/],
    ['a bad company email', { companyEmail: 'a@b' }, /valid email/],
    ['a secret', { SMTP_PASS: 'x' }, /not a setting/],
    ['an unknown name', { nothing: 'x' }, /not a setting/],
    ['something other than text', { companyName: 5 }, /must be text/],
    ['too long', { companyName: 'x'.repeat(201) }, /too long/],
  ])('%s is refused, and nothing is saved', async (_name, values, message) => {
    const { settings, prisma } = setup();
    await expect(settings.update(values, actor)).rejects.toThrow(BadRequestException);
    await expect(settings.update(values, actor)).rejects.toThrow(message);
    expect(prisma.appSetting.upsert).not.toHaveBeenCalled();
  });

  it('no secret can ever be returned', async () => {
    const { settings } = setup();
    const list = JSON.stringify(await settings.list());
    const values = JSON.stringify(await settings.values());
    expect(list + values).not.toContain('secret-');
    const names = APP_SETTINGS.map((s) => (s.env as string).toUpperCase()).join(' ');
    expect(names).not.toMatch(/PASS|SECRET|KEY|TOKEN|DATABASE|SMTP_/);
  });

  it('the audit log names what changed, without the values', async () => {
    const { settings, audit } = setup();
    await settings.update({ bankAccountNumber: '12345678', companyName: '' }, actor);
    const call = (audit.log.mock.calls as any[])[0][0];
    expect(call.action).toBe('app_settings.updated');
    expect(call.metadata).toEqual({ settings: ['bankAccountNumber'] });
    expect(JSON.stringify(call)).not.toContain('12345678');
  });

  it('saving with no change writes nothing and logs nothing', async () => {
    const { settings, audit, prisma } = setup({ companyName: 'New Co' });
    await settings.update({ companyName: 'New Co', companyPhone: '' }, actor);
    expect(prisma.appSetting.upsert).not.toHaveBeenCalled();
    expect(audit.log).not.toHaveBeenCalled();
  });
});

describe('InvoicePdfService uses the settings when it prints', () => {
  const invoice = {
    invoiceNumber: 'INV-1',
    status: 'ISSUED',
    client: { email: 'c@example.com', firstName: 'Grace', lastName: 'Hill' },
    items: [{ description: 'Survey', quantity: 1, unitPrice: 100, amount: 100 }],
    subtotal: 100,
    taxRate: 20,
    taxAmount: 20,
    total: 120,
    issueDate: '2026-11-04',
    dueDate: '2026-11-18',
  } as any;

  it('reads them afresh for each invoice', async () => {
    const { settings } = setup();
    const spy = jest.spyOn(settings, 'values');
    const pdf = new InvoicePdfService(settings);
    const first = await pdf.generateInvoicePdf(invoice);
    await settings.update({ companyName: 'New Co', bankAccountNumber: '12345678' }, actor);
    const second = await pdf.generateInvoicePdf(invoice);
    expect(spy).toHaveBeenCalledTimes(2);
    expect(first.subarray(0, 4).toString()).toBe('%PDF');
    expect(second.subarray(0, 4).toString()).toBe('%PDF');
    expect(second.length).toBeGreaterThan(first.length);
  });
});
