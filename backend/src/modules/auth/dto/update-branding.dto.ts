import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class UpdateBrandingDto {
  @ApiPropertyOptional({ example: 'Francis Blackstone Surveyor', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255, { message: 'Company name must be at most 255 characters' })
  companyName?: string | null;

  @ApiPropertyOptional({ description: 'Company logo image, base64 encoded' })
  @IsOptional()
  @IsString()
  @MaxLength(2000000, { message: 'Company logo is too large' })
  @Matches(/^[A-Za-z0-9+/]+={0,2}$/, { message: 'Company logo must be base64 encoded' })
  companyLogo?: string | null;
}

export class BrandingResponseDto {
  @ApiProperty({ nullable: true })
  companyName: string | null;

  @ApiProperty({ nullable: true })
  companyLogo: string | null;
}
