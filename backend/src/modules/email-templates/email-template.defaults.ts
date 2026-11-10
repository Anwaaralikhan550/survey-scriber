// The wording of every email the system sends. Admins can replace these on the
// Email Templates page; without an edit, this is what goes out.
//
// {{name}} fills in a value, HTML-escaped in the HTML version. Names in RAW_HTML_PLACEHOLDERS
// are finished blocks built by the code, because they disappear when there is nothing to show.

export interface EmailTemplateDefault {
  key: string;
  name: string;
  audience: string;
  subject: string;
  html: string;
  text: string;
  /** Placeholder -> what it holds. */
  placeholders: Record<string, string>;
}

export const RAW_HTML_PLACEHOLDERS = ['propertyRow', 'paymentTermsBlock'];

export const EMAIL_TEMPLATE_DEFAULTS: EmailTemplateDefault[] = [
  {
    key: "password_reset",
    name: "Password reset",
    audience: "Anyone who asks to reset their password",
    subject: "Reset your {{appName}} password",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 32px 16px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background-color: #f5f5f5; color: #333333;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; padding: 32px; font-size: 16px; line-height: 1.6;">
    <p style="margin: 0 0 16px;">Hi {{fullName}},</p>
    <p style="margin: 0 0 16px;">You recently requested a new password. Please ignore this email if you have not made this request, no changes have been made to your account, yet. Otherwise, you can reset your password by clicking the link below:</p>
    <p style="margin: 0 0 16px;"><a href="{{resetLink}}" style="color: #1565C0; word-break: break-all;">{{resetLink}}</a></p>
    <p style="margin: 0 0 16px;">This password reset link is only valid for 30 minutes from the time of your request.</p>
    <p style="margin: 0;">Thanks<br>{{appName}} Team</p>
  </div>
</body>
</html>`,
    text: `Hi {{fullName}},

You recently requested a new password. Please ignore this email if you have not made this request, no changes have been made to your account, yet. Otherwise, you can reset your password by clicking the link below:

{{resetLink}}

This password reset link is only valid for 30 minutes from the time of your request.

Thanks
{{appName}} Team`,
    placeholders: {
      fullName: "First and last name",
      resetLink: "The reset link (secret, works once)",
      appName: "The app name",
    },
  },
  {
    key: "account_invite",
    name: "New account invitation",
    audience: "Field users and sub admins added on this site",
    subject: "Your {{appName}} account is ready",
    html: `
<!DOCTYPE html>
<html lang="en">
<body style="margin: 0; padding: 32px 16px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background-color: #f5f5f5; color: #222222;">
  <div style="max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 8px; padding: 32px;">
    <h1 style="margin: 0 0 16px; font-size: 20px;">Welcome to {{appName}}</h1>
    <p style="margin: 0 0 16px;">Hello {{firstName}},</p>
    <p style="margin: 0 0 24px;">An account has been created for you. Set your password to sign in. This link stays open for 7 days.</p>
    <p style="margin: 0 0 24px;"><a href="{{link}}" style="display: inline-block; padding: 12px 24px; background: #1565C0; color: #ffffff; text-decoration: none; border-radius: 6px;">Set your password</a></p>
    <p style="margin: 0; font-size: 13px; color: #666666;">If you were not expecting this email, you can ignore it.</p>
  </div>
</body>
</html>`,
    text: `Hello {{firstName}},

An account has been created for you on {{appName}}. Set your password to sign in (the link stays open for 7 days):

{{link}}

If you were not expecting this email, you can ignore it.`,
    placeholders: {
      firstName: "First name",
      link: "The set-password link (secret, works once)",
      appName: "The app name",
    },
  },
  {
    key: "magic_link",
    name: "Client portal login link",
    audience: "Clients signing in to the portal",
    subject: "Your {{appName}} login link",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Login Link</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
              <p style="margin: 8px 0 0; color: rgba(255,255,255,0.9); font-size: 14px;">
                Client Portal
              </p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
                Your Login Link
              </h2>

              <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
                Hi {{firstName}},
              </p>

              <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
                Click the button below to securely access your {{appName}} Client Portal.
                You can view your bookings and survey reports.
              </p>

              <table role="presentation" style="margin: 30px 0; width: 100%;">
                <tr>
                  <td align="center">
                    <a href="{{loginLink}}"
                       style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
                      Access Client Portal
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
                This link will expire in <strong>{{expiryMinutes}} minutes</strong> for security reasons.
              </p>

              <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
                If you didn't request this link, you can safely ignore this email.
              </p>

              <!-- Alternative link -->
              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eeeeee;">
                <p style="margin: 0 0 10px; color: #888888; font-size: 13px;">
                  If the button above doesn't work, copy and paste this link into your browser:
                </p>
                <p style="margin: 0; word-break: break-all;">
                  <a href="{{loginLink}}" style="color: #1976d2; font-size: 13px;">{{loginLink}}</a>
                </p>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} Client Portal - Your Login Link

Hi {{firstName}},

Click the link below to securely access your {{appName}} Client Portal.
You can view your bookings and survey reports.

{{loginLink}}

This link will expire in {{expiryMinutes}} minutes for security reasons.

If you didn't request this link, you can safely ignore this email.

---
This is an automated message from {{appName}}.`,
    placeholders: {
      firstName: "First name, or \"there\"",
      loginLink: "The login link (secret, works once)",
      expiryMinutes: "Minutes until the link stops working",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_created_client",
    name: "Booking scheduled (client)",
    audience: "The client, when a booking is made",
    subject: "Your survey booking has been scheduled - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        Booking Confirmation
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Your survey booking has been scheduled. Here are the details:
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{startTime}} - {{endTime}}</td>
        </tr>
        {{propertyRow}}
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{surveyorName}}</td>
        </tr>
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="{{bookingLink}}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Booking
            </a>
          </td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Booking Confirmation

Hi {{clientName}},

Your survey booking has been scheduled:

Date: {{bookingDate}}
Time: {{startTime}} - {{endTime}}
{{propertyLine}}
Surveyor: {{surveyorName}}

View your booking: {{bookingLink}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      bookingDate: "Date of the booking",
      startTime: "Start time",
      endTime: "End time",
      surveyorName: "Surveyor's name",
      propertyRow: "Property row in the table. Empty when the booking has no address.",
      propertyLine: "Property line in the text version. Empty when the booking has no address.",
      bookingLink: "Link to the booking in the client portal",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_created_surveyor",
    name: "Booking assigned (surveyor)",
    audience: "The surveyor, when a booking is made",
    subject: "New booking assigned: {{bookingDate}} - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        New Booking Assigned
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A new survey booking has been assigned to you.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Client</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{clientName}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{startTime}} - {{endTime}}</td>
        </tr>
        {{propertyRow}}
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="{{staffBookingLink}}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Booking
            </a>
          </td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - New Booking Assigned

A new survey booking has been assigned to you:

Client: {{clientName}}
Date: {{bookingDate}}
Time: {{startTime}} - {{endTime}}
{{propertyLine}}

View booking: {{staffBookingLink}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's name",
      bookingDate: "Date of the booking",
      startTime: "Start time",
      endTime: "End time",
      propertyRow: "Property row in the table. Empty when the booking has no address.",
      propertyLine: "Property line in the text version. Empty when the booking has no address.",
      staffBookingLink: "Link to the booking in the staff app",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_confirmed",
    name: "Booking confirmed",
    audience: "The client, when the surveyor confirms",
    subject: "Your booking for {{bookingDate}} is confirmed - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #4caf50; font-size: 20px; font-weight: 600;">
        Booking Confirmed
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Great news! Your survey booking has been confirmed by your surveyor.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{startTime}} - {{endTime}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{surveyorName}}</td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Booking Confirmed

Hi {{clientName}},

Great news! Your survey booking has been confirmed.

Date: {{bookingDate}}
Time: {{startTime}} - {{endTime}}
Surveyor: {{surveyorName}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      bookingDate: "Date of the booking",
      startTime: "Start time",
      endTime: "End time",
      surveyorName: "Surveyor's name",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_cancelled_client",
    name: "Booking cancelled (client)",
    audience: "The client, when a booking is cancelled",
    subject: "Your booking for {{bookingDate}} has been cancelled - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #f44336; font-size: 20px; font-weight: 600;">
        Booking Cancelled
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        We're sorry to inform you that your survey booking has been cancelled.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{startTime}} - {{endTime}}</td>
        </tr>
      </table>
      <p style="margin: 20px 0; color: #555555; font-size: 14px; line-height: 1.6;">
        If you have any questions, please contact us.
      </p>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Booking Cancelled

Hi {{clientName}},

Your survey booking has been cancelled.

Date: {{bookingDate}}
Time: {{startTime}} - {{endTime}}

If you have any questions, please contact us.

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      bookingDate: "Date of the booking",
      startTime: "Start time",
      endTime: "End time",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_cancelled_surveyor",
    name: "Booking cancelled (surveyor)",
    audience: "The surveyor, when a booking is cancelled",
    subject: "Booking cancelled: {{bookingDate}} - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #f44336; font-size: 20px; font-weight: 600;">
        Booking Cancelled
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A booking has been cancelled.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Client</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{clientName}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{startTime}} - {{endTime}}</td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Booking Cancelled

A booking has been cancelled:

Client: {{clientName}}
Date: {{bookingDate}}
Time: {{startTime}} - {{endTime}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's name",
      bookingDate: "Date of the booking",
      startTime: "Start time",
      endTime: "End time",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "booking_completed",
    name: "Survey completed",
    audience: "The client, when the booking is completed",
    subject: "Your survey has been completed - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #2196f3; font-size: 20px; font-weight: 600;">
        Survey Completed
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Your survey has been completed. Once the report is finalized and approved, you will be able to access it in your client portal.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{bookingDate}}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{surveyorName}}</td>
        </tr>
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="{{portalLink}}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Portal
            </a>
          </td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Survey Completed

Hi {{clientName}},

Your survey has been completed.

Date: {{bookingDate}}
Surveyor: {{surveyorName}}

Once the report is finalized and approved, you can access it in your client portal:
{{portalLink}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      bookingDate: "Date of the booking",
      surveyorName: "Surveyor's name",
      portalLink: "Link to the client portal",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "invoice_issued",
    name: "Invoice issued",
    audience: "The client, when an invoice is issued",
    subject: "Invoice {{invoiceNumber}} - {{total}} - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        New Invoice
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A new invoice has been issued for your account. Please see the details below:
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #f9f9f9; border-radius: 8px;">
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888; width: 140px;">Invoice Number</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 600;">{{invoiceNumber}}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888;">Issue Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{issueDate}}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888;">Due Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">{{dueDate}}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; color: #888888;">Total Amount</td>
          <td style="padding: 16px 20px; color: #1976d2; font-size: 20px; font-weight: 700;">{{total}}</td>
        </tr>
      </table>
      {{paymentTermsBlock}}
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="{{invoiceLink}}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Invoice
            </a>
          </td>
        </tr>
      </table>
      <p style="margin: 20px 0; color: #888888; font-size: 13px; line-height: 1.6; text-align: center;">
        You can download a PDF copy of this invoice from your client portal.
      </p>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - New Invoice

Hi {{clientName}},

A new invoice has been issued for your account:

Invoice Number: {{invoiceNumber}}
Issue Date: {{issueDate}}
Due Date: {{dueDate}}
Total Amount: {{total}}

{{paymentTermsLine}}

View invoice: {{invoiceLink}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      invoiceNumber: "Invoice number",
      issueDate: "Issue date",
      dueDate: "Due date",
      total: "Total amount",
      paymentTermsBlock: "Payment terms paragraph. Empty when the invoice has none.",
      paymentTermsLine: "Payment terms line in the text version. Empty when the invoice has none.",
      invoiceLink: "Link to the invoice in the client portal",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "invoice_paid",
    name: "Payment received",
    audience: "The client, when an invoice is paid",
    subject: "Payment Received - Invoice {{invoiceNumber}} - {{appName}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                {{appName}}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              
      <h2 style="margin: 0 0 20px; color: #4caf50; font-size: 20px; font-weight: 600;">
        Payment Received - Thank You!
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi {{clientName}},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        We've received your payment. Thank you for settling your invoice promptly.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #e8f5e9; border-radius: 8px;">
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #2e7d32; width: 140px;">Invoice Number</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #1b5e20; font-weight: 600;">{{invoiceNumber}}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #2e7d32;">Payment Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #1b5e20; font-weight: 500;">{{paidDate}}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; color: #2e7d32;">Amount Paid</td>
          <td style="padding: 16px 20px; color: #1b5e20; font-size: 20px; font-weight: 700;">{{total}}</td>
        </tr>
      </table>
      <div style="margin: 30px 0; padding: 20px; background-color: #f5f5f5; border-radius: 8px; text-align: center;">
        <span style="display: inline-block; padding: 8px 24px; background-color: #4caf50; color: #ffffff; font-size: 14px; font-weight: 600; border-radius: 20px;">
          PAID IN FULL
        </span>
      </div>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="{{invoiceLink}}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Receipt
            </a>
          </td>
        </tr>
      </table>
    
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from {{appName}}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; {{year}} {{appName}}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    text: `{{appName}} - Payment Received

Hi {{clientName}},

Thank you for your payment!

Invoice Number: {{invoiceNumber}}
Payment Date: {{paidDate}}
Amount Paid: {{total}}

Status: PAID IN FULL

View receipt: {{invoiceLink}}

---
This is an automated message from {{appName}}.`,
    placeholders: {
      clientName: "Client's first name",
      invoiceNumber: "Invoice number",
      paidDate: "Payment date",
      total: "Amount paid",
      invoiceLink: "Link to the receipt in the client portal",
      appName: "The app name",
      year: "This year",
    },
  },
  {
    key: "survey_report",
    name: "Survey report",
    audience: "Whoever a report is sent to",
    subject: "Survey Report - {{surveyTitle}}",
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 32px 16px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background-color: #f5f5f5; color: #333333;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; padding: 32px; font-size: 16px; line-height: 1.6;">
    <p style="margin: 0 0 16px;">This is an automatically generated email from an unmonitored email address. Please, do not reply to this email address.</p>
    <p style="margin: 0 0 16px;">Please find your generated inspection report attached. Please, download and store a copy on your device or PC, no copy is stored on the server.</p>
    <p style="margin: 0 0 16px;">Please, extract the report and image file to the same location on your device or PC to view the embedded images.</p>
    <p style="margin: 0;">Regards<br>The SurveyScriber Team.</p>
  </div>
</body>
</html>`,
    text: `This is an automatically generated email from an unmonitored email address. Please, do not reply to this email address.

Please find your generated inspection report attached. Please, download and store a copy on your device or PC, no copy is stored on the server.

Please, extract the report and image file to the same location on your device or PC to view the embedded images.

Regards
The SurveyScriber Team.`,
    placeholders: {
      surveyTitle: "Survey title (subject line)",
    },
  },
];
