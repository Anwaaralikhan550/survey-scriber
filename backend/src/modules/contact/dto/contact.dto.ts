import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class ContactDto {
  @ApiProperty({ example: 'surveyor@example.com' })
  @IsEmail({}, { message: 'Please enter a valid email address' })
  @MaxLength(255)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  email: string;

  @ApiProperty({ example: 'A question about my report' })
  @IsString()
  @MinLength(1, { message: 'Please enter a subject' })
  @MaxLength(200)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  subject: string;

  @ApiProperty({ example: 'Hello, ...' })
  @IsString()
  @MinLength(1, { message: 'Please enter a message' })
  @MaxLength(5000)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  message: string;
}
