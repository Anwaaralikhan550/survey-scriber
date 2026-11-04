import { EmailTemplateDefault, RAW_HTML_PLACEHOLDERS } from './email-template.defaults';

export interface EmailContent {
  subject: string;
  html: string;
  text: string;
}

export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const PLACEHOLDER = /\{\{(\w+)\}\}/g;

export function placeholdersIn(template: string): Set<string> {
  return new Set([...template.matchAll(PLACEHOLDER)].map((m) => m[1]));
}

/** One pass only, so a value that happens to contain {{name}} stays as typed. */
function fill(template: string, read: (name: string) => string): string {
  return template.replace(PLACEHOLDER, (_, name: string) => read(name));
}

export function fillTemplate(
  template: EmailContent,
  values: Record<string, string>,
  rawHtml: Record<string, string> = {},
): EmailContent {
  const plain = (name: string) => values[name] ?? '';
  return {
    // A subject is one line, whatever a value contains.
    subject: fill(template.subject, plain).replace(/[\r\n]+/g, ' ').trim(),
    html: fill(template.html, (name) =>
      RAW_HTML_PLACEHOLDERS.includes(name) ? (rawHtml[name] ?? '') : escapeHtml(plain(name)),
    ),
    text: fill(template.text, plain),
  };
}

const PART_NAMES: Record<keyof EmailContent, string> = { subject: 'subject', html: 'HTML version', text: 'text version' };

/** What stops an edit being saved, or null. Placeholders stay exactly as they are in the original. */
export function problemWith(edit: EmailContent, original: EmailTemplateDefault): string | null {
  for (const part of ['subject', 'html', 'text'] as const) {
    const value = edit[part];
    if (typeof value !== 'string' || !value.trim()) return `The ${PART_NAMES[part]} cannot be empty.`;
    const now = placeholdersIn(value);
    const wanted = placeholdersIn(original[part]);
    for (const name of now) {
      if (!wanted.has(name)) return `{{${name}}} is not available in the ${PART_NAMES[part]} of this email.`;
    }
    for (const name of wanted) {
      if (!now.has(name)) return `The ${PART_NAMES[part]} must keep {{${name}}}.`;
    }
  }
  if (/<script\b/i.test(edit.html)) return 'Scripts are not allowed in an email.';
  if (edit.html.length > 200_000 || edit.text.length > 50_000 || edit.subject.length > 300) {
    return 'This email is too long.';
  }
  return null;
}

export function propertyRowHtml(address: string | null | undefined): string {
  if (!address) return '';
  return `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Property</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${escapeHtml(address)}</td>
        </tr>
        `;
}

export function paymentTermsHtml(terms: string | null | undefined): string {
  if (!terms) return '';
  return `
      <p style="margin: 20px 0 10px; color: #666666; font-size: 14px; font-weight: 600;">
        Payment Terms:
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
        ${escapeHtml(terms)}
      </p>
      `;
}

/** Made-up values for previews and test emails. */
export const SAMPLE_VALUES: Record<string, string> = {
  firstName: 'Grace',
  clientName: 'Grace',
  bookingDate: 'Tuesday 1 December 2026',
  startTime: '09:00',
  endTime: '11:00',
  surveyorName: 'Sam Lee',
  propertyLine: 'Property: 10 Oak Road, Leeds',
  bookingLink: 'https://example.com/booking',
  staffBookingLink: 'https://example.com/booking',
  portalLink: 'https://example.com/portal',
  invoiceNumber: 'INV-2026-0001',
  issueDate: 'Wednesday 2 December 2026',
  dueDate: 'Wednesday 16 December 2026',
  paidDate: 'Saturday 5 December 2026',
  total: '£540.00',
  paymentTermsLine: 'Payment Terms: Net 14 days',
  invoiceLink: 'https://example.com/invoice',
  surveyTitle: 'Inspection - 10 Oak Road',
  senderName: 'Sam Lee',
  resetLink: 'https://example.com/test-only',
  link: 'https://example.com/test-only',
  loginLink: 'https://example.com/test-only',
  expiryMinutes: '15',
};

export const SAMPLE_RAW_HTML: Record<string, string> = {
  propertyRow: propertyRowHtml('10 Oak Road, Leeds'),
  paymentTermsBlock: paymentTermsHtml('Net 14 days'),
};
