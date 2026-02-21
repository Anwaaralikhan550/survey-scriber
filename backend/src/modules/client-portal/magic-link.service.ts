import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import * as nodemailer from 'nodemailer';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MagicLinkService {
  private readonly logger = new Logger(MagicLinkService.name);
  private readonly transporter: nodemailer.Transporter | null;
  private readonly fromAddress: string;
  private readonly appName: string;
  private readonly frontendUrl: string;
  private readonly clientPortalUrl: string;
  private readonly magicLinkExpiryMinutes: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    // Magic link expiry: use config (in seconds) or default to 15 minutes
    const expirySeconds = this.configService.get<number>('MAGIC_LINK_EXPIRY_SECONDS', 900);
    this.magicLinkExpiryMinutes = Math.ceil(expirySeconds / 60);
    // SMTP configuration from environment
    const host = this.configService.get<string>('SMTP_HOST');
    const port = this.configService.get<number>('SMTP_PORT') || 587;
    const secure = this.configService.get<boolean>('SMTP_SECURE') || false;
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    this.fromAddress = this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    this.appName = this.configService.get<string>('APP_NAME') || 'SurveyScriber';
    this.frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
    this.clientPortalUrl = this.configService.get<string>('CLIENT_PORTAL_URL') || this.frontendUrl;

    // Create transporter only if SMTP is configured
    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      });
      this.logger.log('SMTP configured for magic link emails');
    } else {
      this.transporter = null;
      this.logger.warn('SMTP not configured - magic link emails will be logged only');
    }
  }

  /**
   * Generate a cryptographically secure magic link token.
   * Returns the plain token (to be sent via email) and its hash (to store in DB).
   */
  generateToken(): { plainToken: string; tokenHash: string } {
    // 64 bytes = 128 hex chars = 512 bits of entropy
    const plainToken = crypto.randomBytes(64).toString('hex');
    const tokenHash = this.hashToken(plainToken);
    return { plainToken, tokenHash };
  }

  /**
   * Hash a token using SHA-256.
   */
  hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Create and store a magic link for a client.
   * Returns the plain token to be sent via email.
   */
  async createMagicLink(clientId: string): Promise<string> {
    const { plainToken, tokenHash } = this.generateToken();

    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + this.magicLinkExpiryMinutes);

    // Store the hashed token
    await this.prisma.clientMagicLink.create({
      data: {
        clientId,
        tokenHash,
        expiresAt,
      },
    });

    // Clean up old/expired tokens for this client
    await this.prisma.clientMagicLink.deleteMany({
      where: {
        clientId,
        OR: [
          { expiresAt: { lt: new Date() } },
          { usedAt: { not: null } },
        ],
      },
    });

    return plainToken;
  }

  /**
   * Verify a magic link token.
   * Returns the client ID if valid, null otherwise.
   * Marks the token as used.
   */
  async verifyMagicLink(plainToken: string): Promise<string | null> {
    const tokenHash = this.hashToken(plainToken);

    const magicLink = await this.prisma.clientMagicLink.findFirst({
      where: {
        tokenHash,
        usedAt: null,
        expiresAt: { gte: new Date() },
      },
      include: {
        client: true,
      },
    });

    if (!magicLink) {
      this.logger.debug('Magic link verification failed: token not found or expired');
      return null;
    }

    if (!magicLink.client.isActive) {
      this.logger.debug('Magic link verification failed: client inactive');
      return null;
    }

    // Mark token as used (single-use)
    await this.prisma.clientMagicLink.update({
      where: { id: magicLink.id },
      data: { usedAt: new Date() },
    });

    this.logger.log(`Magic link verified for client: ${magicLink.client.email}`);
    return magicLink.clientId;
  }

  /**
   * Send magic link email to client.
   */
  async sendMagicLinkEmail(
    toEmail: string,
    firstName: string | null,
    plainToken: string,
  ): Promise<void> {
    const loginLink = `${this.clientPortalUrl}/client/verify?token=${plainToken}`;
    const displayName = firstName || 'there';

    const subject = `Your ${this.appName} login link`;
    const html = this.getMagicLinkEmailTemplate(displayName, loginLink);
    const text = this.getMagicLinkEmailText(displayName, loginLink);

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
      this.logger.log(`[DEV] Magic link email would be sent to: ${to}`);
      this.logger.log(`[DEV] Subject: ${subject}`);
      this.logger.log(`[DEV] Content:\n${text}`);
      return;
    }

    try {
      const info = await this.transporter.sendMail(mailOptions);
      this.logger.log(`Magic link email sent: ${info.messageId} to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send magic link email to ${to}: ${error}`);
      throw error;
    }
  }

  private getMagicLinkEmailTemplate(displayName: string, loginLink: string): string {
    return `
<!DOCTYPE html>
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
                ${this.appName}
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
                Hi ${displayName},
              </p>

              <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
                Click the button below to securely access your ${this.appName} Client Portal.
                You can view your bookings and survey reports.
              </p>

              <table role="presentation" style="margin: 30px 0; width: 100%;">
                <tr>
                  <td align="center">
                    <a href="${loginLink}"
                       style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
                      Access Client Portal
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
                This link will expire in <strong>${this.magicLinkExpiryMinutes} minutes</strong> for security reasons.
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
                  <a href="${loginLink}" style="color: #1976d2; font-size: 13px;">${loginLink}</a>
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

  private getMagicLinkEmailText(displayName: string, loginLink: string): string {
    return `
${this.appName} Client Portal - Your Login Link

Hi ${displayName},

Click the link below to securely access your ${this.appName} Client Portal.
You can view your bookings and survey reports.

${loginLink}

This link will expire in ${this.magicLinkExpiryMinutes} minutes for security reasons.

If you didn't request this link, you can safely ignore this email.

---
This is an automated message from ${this.appName}.
    `.trim();
  }
}
