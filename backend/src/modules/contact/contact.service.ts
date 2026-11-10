import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { EmailService } from '../auth/email.service';
import { EmailTemplatesService } from '../email-templates/email-templates.service';
import { ContactDto } from './dto/contact.dto';

interface Sender {
  id: string;
  firstName?: string | null;
  lastName?: string | null;
  email: string;
}

@Injectable()
export class ContactService {
  constructor(
    private readonly emailService: EmailService,
    private readonly templates: EmailTemplatesService,
  ) {}

  /** Sends what the person typed to the support address. Fails loudly: they must know it did not go. */
  async send(user: Sender, dto: ContactDto): Promise<{ sent: true }> {
    const to = await this.templates.supportAddress();
    const userName = [user.firstName, user.lastName].filter(Boolean).join(' ') || user.email;
    try {
      await this.emailService.sendContactEmail(to, {
        email: dto.email,
        subject: dto.subject,
        message: dto.message,
        userName,
        userId: user.id,
      });
    } catch {
      throw new ServiceUnavailableException('Your message could not be sent. Please try again in a few minutes.');
    }
    return { sent: true };
  }
}
