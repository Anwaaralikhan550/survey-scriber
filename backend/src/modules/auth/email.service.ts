import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { ApiUrlBuilder } from '../../common/utils/api-url.util';
import { EmailTemplatesService } from '../email-templates/email-templates.service';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter: nodemailer.Transporter;
  private readonly fromAddress: string;
  private readonly frontendUrl: string;
  private readonly urlBuilder: ApiUrlBuilder;

  constructor(
    private readonly configService: ConfigService,
    private readonly templates: EmailTemplatesService,
  ) {
    // SMTP configuration from environment
    const host = this.configService.get<string>('SMTP_HOST');
    const port = parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10);
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    this.fromAddress = this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    this.urlBuilder = new ApiUrlBuilder(configService);
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
    lastName = '',
  ): Promise<void> {
    const resetLink = `${this.frontendUrl}/reset-password?token=${resetToken}`;
    const fullName = [firstName, lastName].filter(Boolean).join(' ');

    const { subject, html, text } = await this.templates.render('password_reset', { fullName, resetLink });

    await this.sendEmail(toEmail, subject, html, text);
  }

  /** The link in the sign-up email. It opens a small page on the server that activates the account. */
  async sendActivationEmail(
    toEmail: string,
    firstName: string,
    token: string,
    lastName = '',
  ): Promise<void> {
    const activateLink = `${await this.templates.publicUrl()}${this.urlBuilder.build('/auth/activate')}?token=${token}`;
    const fullName = [firstName, lastName].filter(Boolean).join(' ');
    const { subject, html, text } = await this.templates.render('sign_up', { fullName, activateLink });
    await this.sendEmail(toEmail, subject, html, text);
  }

  /** What someone typed in Contact Us, sent to the support address. */
  async sendContactEmail(
    toEmail: string,
    details: { email: string; subject: string; message: string; userName: string; userId: string },
  ): Promise<void> {
    const { subject, html, text } = await this.templates.render('contact_us', details);
    await this.sendEmail(toEmail, subject, html, text);
  }

  /**
   * Tell a user added by an administrator that their account is ready.
   */
  async sendAccountInviteEmail(
    toEmail: string,
    firstName: string,
    token: string,
  ): Promise<void> {
    const link = `${this.frontendUrl}/reset-password?token=${token}`;
    const { subject, html, text } = await this.templates.render('account_invite', { firstName, link });
    await this.sendEmail(toEmail, subject, html, text);
  }

  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    text: string,
  ): Promise<void> {
    const mailOptions = {
      ...(await this.templates.sender(this.fromAddress)),
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

}
