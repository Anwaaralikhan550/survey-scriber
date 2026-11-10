import * as fs from 'fs';
import * as path from 'path';
import { BadRequestException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailService } from '../auth/email.service';
import { MagicLinkService } from '../client-portal/magic-link.service';
import { NotificationEmailService } from '../notifications/notification-email.service';
import { EMAIL_TEMPLATE_DEFAULTS } from './email-template.defaults';
import { EmailContent, fillTemplate, placeholdersIn, problemWith } from './email-template.helpers';
import { EmailTemplatesService } from './email-templates.service';

// What every email said before templates existed.
const baseline = JSON.parse(fs.readFileSync(path.join(__dirname, '__fixtures__', 'baseline.json'), 'utf8'));

const settings: Record<string, string> = {
  APP_NAME: 'SurveyScriber',
  FRONTEND_URL: 'https://app.example.com',
  CLIENT_PORTAL_URL: 'https://app.example.com/client',
};
const config = { get: (key: string, fallback?: unknown) => settings[key] ?? fallback } as unknown as ConfigService;

const booking = {
  id: 'b1',
  date: new Date('2026-12-01T00:00:00Z'),
  startTime: '09:00',
  endTime: '11:00',
  propertyAddress: '10 Oak Road, Leeds',
  clientName: 'Grace Hill',
  client: { id: 'c1', firstName: 'Grace', email: 'grace@example.com' },
  surveyor: { id: 'u1', firstName: 'Sam', lastName: 'Lee', email: 'sam@example.com' },
} as any;
const invoice = {
  id: 'i1',
  invoiceNumber: 'INV-2026-0001',
  issueDate: new Date('2026-12-02T00:00:00Z'),
  dueDate: new Date('2026-12-16T00:00:00Z'),
  paidDate: new Date('2026-12-05T00:00:00Z'),
  total: 54000,
  paymentTerms: 'Net 14 days',
  client: { id: 'c1', firstName: 'Grace', email: 'grace@example.com' },
} as any;
const actor = { id: 'admin', email: 'boss@example.com' };

function setup(stored: Record<string, EmailContent> = {}) {
  const prisma = {
    emailTemplate: {
      findUnique: jest.fn(async ({ where }: any) => (stored[where.key] ? { key: where.key, ...stored[where.key] } : null)),
      findMany: jest.fn(async () => Object.entries(stored).map(([key, v]) => ({ key, ...v }))),
      upsert: jest.fn(async ({ where, create }: any) => { stored[where.key] = create; }),
      deleteMany: jest.fn(async ({ where }: any) => { delete stored[where.key]; }),
    },
    notificationEmailLog: { create: jest.fn(async () => ({})) },
  };
  const audit = { log: jest.fn(async () => undefined) };
  const settings = {
    values: jest.fn(async () => ({ appName: 'SurveyScriber', senderName: 'SurveyScriber', supportEmail: '' })),
  };
  const templates = new EmailTemplatesService(prisma as never, config, audit as never, settings as never);
  const sent: any[] = [];
  const transporter = { sendMail: jest.fn(async (mail: any) => { sent.push(mail); return { messageId: 'x' }; }) };
  const notifications = new NotificationEmailService(config, prisma as never, templates) as any;
  notifications.transporter = transporter;
  const auth = new EmailService(config, templates) as any;
  auth.transporter = transporter;
  const magic = new MagicLinkService(prisma as never, config, templates) as any;
  magic.transporter = transporter;
  return { prisma, audit, settings, templates, sent, notifications, auth, magic };
}

const same = (mail: any, want: any) => {
  if (want.subject) expect(mail.subject).toBe(want.subject);
  expect(mail.html).toBe(want.html);
  expect(mail.text).toBe(want.text);
};

// Client file (4), 10 Nov 2026: the wording of the Report and Forgot Password emails.
const CLIENT_REPORT_TEXT = [
  'This is an automatically generated email from an unmonitored email address. Please, do not reply to this email address.',
  'Please find your generated inspection report attached. Please, download and store a copy on your device or PC, no copy is stored on the server.',
  'Please, extract the report and image file to the same location on your device or PC to view the embedded images.',
  'Regards\nThe SurveyScriber Team.',
].join('\n\n');
const CLIENT_RESET_TEXT = [
  'Hi Grace,',
  'You recently requested a new password. Please ignore this email if you have not made this request, no changes have been made to your account, yet. Otherwise, you can reset your password by clicking the link below:',
  'https://app.example.com/reset-password?token=abc',
  'This password reset link is only valid for 30 minutes from the time of your request.',
  'Thanks\nSurveyScriber Team',
].join('\n\n');

describe('with no edits, every email is word for word what it was', () => {
  beforeAll(() => jest.useFakeTimers({ now: new Date('2026-11-04T10:00:00Z'), doNotFake: ['nextTick', 'setImmediate'] }));
  afterAll(() => jest.useRealTimers());

  it('booking created: client and surveyor', async () => {
    const { notifications, sent } = setup();
    await notifications.sendBookingCreatedEmails(booking);
    same(sent[0], baseline.booking_created_client);
    same(sent[1], baseline.booking_created_surveyor);
  });

  it('booking created with no address', async () => {
    const { notifications, sent } = setup();
    await notifications.sendBookingCreatedEmails({ ...booking, propertyAddress: null });
    same(sent[0], baseline.booking_created_client_no_property);
    same(sent[1], baseline.booking_created_surveyor_no_property);
  });

  it('booking confirmed, cancelled, completed', async () => {
    const { notifications, sent } = setup();
    await notifications.sendBookingConfirmedEmail(booking);
    await notifications.sendBookingCancelledEmails(booking);
    await notifications.sendBookingCompletedEmail(booking);
    same(sent[0], baseline.booking_confirmed);
    same(sent[1], baseline.booking_cancelled_client);
    same(sent[2], baseline.booking_cancelled_surveyor);
    same(sent[3], baseline.booking_completed);
  });

  it('invoice issued and paid, with and without the optional parts', async () => {
    const { notifications, sent } = setup();
    const bare = { ...invoice, paymentTerms: null, dueDate: null, issueDate: null, paidDate: null };
    await notifications.sendInvoiceIssuedEmail(invoice);
    await notifications.sendInvoiceIssuedEmail(bare);
    await notifications.sendInvoicePaidEmail(invoice);
    await notifications.sendInvoicePaidEmail(bare);
    same(sent[0], baseline.invoice_issued);
    same(sent[1], baseline.invoice_issued_no_terms);
    same(sent[2], baseline.invoice_paid);
    same(sent[3], baseline.invoice_paid_no_date);
  });

  it('survey report keeps its attachment', async () => {
    const { notifications, sent } = setup();
    await notifications.sendSurveyReportEmail('c@example.com', 'Oak Road', Buffer.from('pdf'), 'Sam Lee');
    expect(sent[0].subject).toBe('Survey Report - Oak Road');
    expect(sent[0].text).toBe(CLIENT_REPORT_TEXT);
    expect(sent[0].html).toContain('Please, extract the report and image file to the same location');
    expect(sent[0].attachments[0].filename).toBe('Survey_Report_Oak_Road.pdf');
  });

  it('password reset, invitation, client login link', async () => {
    const { auth, magic, sent } = setup();
    await auth.sendPasswordResetEmail('a@example.com', 'Grace', 'abc');
    await auth.sendAccountInviteEmail('a@example.com', 'Grace', 'abc');
    await magic.sendMagicLinkEmail('a@example.com', 'Grace', 'abc');
    expect(sent[0].subject).toBe('Reset your SurveyScriber password');
    expect(sent[0].text).toBe(CLIENT_RESET_TEXT);
    same(sent[1], baseline.account_invite);
    same(sent[2], baseline.magic_link);
  });
});

describe('edited emails', () => {
  const editOf = (key: string, change: (t: EmailContent) => Partial<EmailContent>): EmailContent => {
    const t = EMAIL_TEMPLATE_DEFAULTS.find((d) => d.key === key)!;
    const base = { subject: t.subject, html: t.html, text: t.text };
    return { ...base, ...change(base) };
  };

  it('the edit goes out, in all three parts', async () => {
    const stored = {
      booking_confirmed: editOf('booking_confirmed', (t) => ({
        subject: 'Confirmed! ' + t.subject,
        html: t.html.replace('Great news!', 'Wonderful news!'),
        text: t.text.replace('Great news!', 'Wonderful news!'),
      })),
    };
    const { notifications, sent } = setup(stored);
    await notifications.sendBookingConfirmedEmail(booking);
    expect(sent[0].subject).toMatch(/^Confirmed! Your booking for /);
    expect(sent[0].html).toContain('Wonderful news!');
    expect(sent[0].text).toContain('Wonderful news!');
  });

  it('a stored edit that no longer fits is ignored', async () => {
    const stored = { booking_confirmed: { subject: 'x', html: '<p>no placeholders</p>', text: 'y' } };
    const { notifications, sent } = setup(stored);
    await notifications.sendBookingConfirmedEmail(booking);
    expect(sent[0].html).toContain('Great news!');
  });

  it('if the database cannot answer, the original email still goes', async () => {
    const { prisma, auth, sent } = setup();
    prisma.emailTemplate.findUnique.mockRejectedValue(new Error('database down'));
    await auth.sendPasswordResetEmail('a@example.com', 'Grace', 'abc');
    expect(sent[0].subject).toBe('Reset your SurveyScriber password');
    expect(sent[0].html).toContain('You recently requested a new password');
  });

  it('a script in a client name stays text in the HTML', async () => {
    const { notifications, sent } = setup();
    await notifications.sendBookingCreatedEmails({
      ...booking,
      propertyAddress: '<img src=x onerror=alert(1)>',
      client: { ...booking.client, firstName: '<script>alert(1)</script>' },
    });
    expect(sent[0].html).not.toContain('<script>');
    expect(sent[0].html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;');
    expect(sent[0].html).not.toContain('<img src=x');
    expect(sent[0].text).toContain('<script>alert(1)</script>');
  });

  it('a value containing {{name}} is not filled in again', () => {
    const out = fillTemplate({ subject: 'S {{a}}', html: '{{a}} {{b}}', text: '{{a}}' }, { a: '{{b}}', b: 'secret' });
    expect(out.subject).toBe('S {{b}}');
    expect(out.html).toBe('{{b}} secret');
  });

  it('a line break cannot get into a subject', () => {
    const out = fillTemplate({ subject: 'Hi {{a}}', html: 'x', text: 'x' }, { a: 'x\r\nBcc: other@example.com' });
    expect(out.subject).toBe('Hi x Bcc: other@example.com');
  });
});

describe('settings in emails', () => {
  it('a changed app name, sender and support email reach the very next email', async () => {
    const { auth, notifications, settings, sent } = setup();
    await auth.sendPasswordResetEmail('a@example.com', 'Grace', 'abc');
    expect(sent[0].from).toEqual({ name: 'SurveyScriber', address: 'noreply@surveyscriber.com' });
    expect(sent[0].replyTo).toBeUndefined();

    settings.values.mockResolvedValue({ appName: 'Acme Surveys', senderName: 'Acme Office', supportEmail: 'help@acme.example' });
    await auth.sendPasswordResetEmail('a@example.com', 'Grace', 'abc');
    await notifications.sendBookingConfirmedEmail(booking);
    await notifications.sendInvoicePaidEmail(invoice);
    await notifications.sendSurveyReportEmail('c@example.com', 'Oak Road', Buffer.from('pdf'), 'Sam Lee');
    for (const mail of sent.slice(1)) {
      expect(mail.from).toEqual({ name: 'Acme Office', address: 'noreply@surveyscriber.com' });
      expect(mail.replyTo).toBe('help@acme.example');
    }
    expect(sent[1].subject).toBe('Reset your Acme Surveys password');
    expect(sent[2].subject).toContain(' - Acme Surveys');
    expect(sent[2].html).toContain('Acme Surveys');
  });
});

describe('saving', () => {
  const t = EMAIL_TEMPLATE_DEFAULTS.find((d) => d.key === 'booking_confirmed')!;
  const good = { subject: t.subject, html: t.html, text: t.text };

  it('every email has what it needs', () => {
    expect(EMAIL_TEMPLATE_DEFAULTS).toHaveLength(12);
    for (const d of EMAIL_TEMPLATE_DEFAULTS) {
      expect(problemWith({ subject: d.subject, html: d.html, text: d.text }, d)).toBeNull();
      const used = new Set([...placeholdersIn(d.subject), ...placeholdersIn(d.html), ...placeholdersIn(d.text)]);
      expect([...used].sort()).toEqual(Object.keys(d.placeholders).sort());
    }
  });

  it.each([
    ['removing a placeholder from the HTML', { html: good.html.replace(/\{\{bookingDate\}\}/g, '') }, /must keep \{\{bookingDate\}\}/],
    ['removing a placeholder from the text', { text: good.text.replace(/\{\{surveyorName\}\}/g, '') }, /text version must keep/],
    ['removing a placeholder from the subject', { subject: 'Confirmed' }, /subject must keep/],
    ['breaking a placeholder', { html: good.html.replace(/\{\{bookingDate\}\}/g, '{{bookingDate}') }, /must keep/],
    ['an unknown placeholder', { html: good.html + '{{password}}' }, /\{\{password\}\} is not available/],
    ['an empty part', { text: '  ' }, /text version cannot be empty/],
    ['a script', { html: good.html + '<SCRIPT>x</SCRIPT>' }, /Scripts are not allowed/],
  ])('%s is refused', async (_name, change, message) => {
    const { templates, prisma } = setup();
    await expect(templates.save('booking_confirmed', { ...good, ...change }, actor)).rejects.toThrow(BadRequestException);
    await expect(templates.save('booking_confirmed', { ...good, ...change }, actor)).rejects.toThrow(message);
    expect(prisma.emailTemplate.upsert).not.toHaveBeenCalled();
  });

  it('save and back to the original are both in the audit log', async () => {
    const stored: Record<string, EmailContent> = {};
    const { templates, audit } = setup(stored);
    const saved = await templates.save('booking_confirmed', { ...good, html: good.html.replace('Great', 'Good') }, actor);
    expect(saved.edited).toBe(true);
    expect(saved.html).toContain('Good news!');
    const reset = await templates.reset('booking_confirmed', actor);
    expect(reset.edited).toBe(false);
    expect(reset.html).toBe(t.html);
    expect(audit.log.mock.calls.map((c: any) => c[0].action)).toEqual(['email_template.updated', 'email_template.reset']);
  });

  it('an unknown email is a 404', async () => {
    const { templates } = setup();
    await expect(templates.get('nope')).rejects.toThrow(NotFoundException);
  });

  it('the list shows all twelve and which are edited', async () => {
    const { templates } = setup({ booking_confirmed: good });
    const list = await templates.list();
    expect(list).toHaveLength(12);
    expect(list.filter((e) => e.edited).map((e) => e.key)).toEqual(['booking_confirmed']);
  });

  it('a preview uses made-up values, never a real link', async () => {
    const { templates } = setup();
    for (const d of EMAIL_TEMPLATE_DEFAULTS) {
      const out = await templates.preview(d.key, { subject: d.subject, html: d.html, text: d.text });
      expect(out.html + out.subject + out.text).not.toMatch(/\{\{\w+\}\}/);
    }
  });

  it('a test email cannot be sent where SMTP is not set up', async () => {
    const { templates } = setup();
    await expect(templates.sendTest('booking_confirmed', good, actor)).rejects.toThrow(ServiceUnavailableException);
  });
});
