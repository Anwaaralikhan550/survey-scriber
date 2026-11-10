import { ServiceUnavailableException } from '@nestjs/common';
import { ContactService } from './contact.service';

const user = { id: 'u-1', firstName: 'Grace', lastName: 'Hill', email: 'grace@example.com' };
const dto = { email: 'reply@example.com', subject: 'My report', message: 'Hello' };

function setup(send = jest.fn(async () => undefined)) {
  const emailService = { sendContactEmail: send };
  const templates = { supportAddress: jest.fn(async () => 'support@example.com') };
  return { service: new ContactService(emailService as never, templates as never), send };
}

describe('ContactService', () => {
  it('sends what was typed, with the sender name and id, to the support address', async () => {
    const { service, send } = setup();
    await expect(service.send(user, dto)).resolves.toEqual({ sent: true });
    expect(send).toHaveBeenCalledWith('support@example.com', {
      email: 'reply@example.com',
      subject: 'My report',
      message: 'Hello',
      userName: 'Grace Hill',
      userId: 'u-1',
    });
  });

  it('falls back to the sign-in email when the user has no name', async () => {
    const { service, send } = setup();
    await service.send({ id: 'u-2', email: 'x@example.com' }, dto);
    expect((send.mock.calls[0] as unknown[])[1]).toMatchObject({ userName: 'x@example.com' });
  });

  it('tells the person when it could not be sent', async () => {
    const { service } = setup(jest.fn(async () => { throw new Error('smtp'); }));
    await expect(service.send(user, dto)).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
