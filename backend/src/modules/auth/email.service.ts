import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter: nodemailer.Transporter;
  private readonly fromAddress: string;
  private readonly appName: string;
  private readonly frontendUrl: string;

  constructor(private readonly configService: ConfigService) {
    // SMTP configuration from environment
    const host = this.configService.get<string>('SMTP_HOST');
    const port = parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10);
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    this.fromAddress = this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    this.appName = this.configService.get<string>('APP_NAME') || 'SurveyScriber';
    this.frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';

    // Create transporter only if SMTP is configured
    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      });

      this.logger.log(`SMTP configured: host=${host}, port=${port}, secure=${secure}`);

      // Verify connection on startup
      this.transporter.verify((error) => {
        if (error) {
          this.logger.error(`SMTP connection error: ${error.message}`);
        } else {
          this.logger.log('SMTP server connection established');
        }
      });
    } else {
      this.logger.warn('SMTP not configured - emails will be logged only');
      // Create a mock transporter that just logs
      this.transporter = null as any;
    }
  }

  /**
   * Send password reset email with professional HTML template.
   */
  async sendPasswordResetEmail(
    toEmail: string,
    firstName: string,
    resetToken: string,
  ): Promise<void> {
    const resetLink = `${this.frontendUrl}/reset-password?token=${resetToken}`;

    const subject = `Reset your ${this.appName} password`;

    const html = this.getPasswordResetEmailTemplate(firstName, resetLink);
    const text = this.getPasswordResetEmailText(firstName, resetLink);

    await this.sendEmail(toEmail, subject, html, text);
  }

  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    text: string,
  ): Promise<void> {
    const mailOptions = {
      from: `"${this.appName}" <${this.fromAddress}>`,
      to,
      subject,
      html,
      text,
    };

    if (!this.transporter) {
      // Log email when SMTP not configured (development mode)
      this.logger.log(`[DEV] Email would be sent to: ${to}`);
      this.logger.log(`[DEV] Subject: ${subject}`);
      this.logger.log(`[DEV] Content:\n${text}`);
      return;
    }

    try {
      const info = await this.transporter.sendMail(mailOptions);
      this.logger.log(`Email sent: ${info.messageId} to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send email to ${to}: ${error}`);
      throw error;
    }
  }

  private getPasswordResetEmailTemplate(firstName: string, resetLink: string): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Password</title>
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
                ${this.appName}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
                Reset Your Password
              </h2>

              <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
                Hi ${firstName},
              </p>

              <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
                We received a request to reset the password for your ${this.appName} account.
                Click the button below to create a new password.
              </p>

              <table role="presentation" style="margin: 30px 0; width: 100%;">
                <tr>
                  <td align="center">
                    <a href="${resetLink}"
                       style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
                      Reset Password
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
                This link will expire in <strong>15 minutes</strong> for security reasons.
              </p>

              <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
                If you didn't request a password reset, you can safely ignore this email.
                Your password will remain unchanged.
              </p>

              <!-- Alternative link -->
              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eeeeee;">
                <p style="margin: 0 0 10px; color: #888888; font-size: 13px;">
                  If the button above doesn't work, copy and paste this link into your browser:
                </p>
                <p style="margin: 0; word-break: break-all;">
                  <a href="${resetLink}" style="color: #1976d2; font-size: 13px;">${resetLink}</a>
                </p>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from ${this.appName}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; ${new Date().getFullYear()} ${this.appName}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    `.trim();
  }

  private getPasswordResetEmailText(firstName: string, resetLink: string): string {
    return `
${this.appName} - Reset Your Password

Hi ${firstName},

We received a request to reset the password for your ${this.appName} account.

To reset your password, visit the following link:
${resetLink}

This link will expire in 15 minutes for security reasons.

If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.

---
This is an automated message from ${this.appName}.
    `.trim();
  }
}
