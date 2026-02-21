import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * A single field in the report with its resolved display value.
 */
export class ReportFieldDto {
  @ApiProperty({ description: 'Field key (e.g. "property_type")' })
  fieldKey: string;

  @ApiProperty({ description: 'Human-readable field label from config' })
  label: string;

  @ApiProperty({ description: 'Field type (text, dropdown, radio, checkbox, number, date, textarea, signature)' })
  fieldType: string;

  @ApiPropertyOptional({ description: 'Raw stored value' })
  rawValue?: string;

  @ApiProperty({ description: 'Human-readable display value (or "Not assessed" if missing)' })
  displayValue: string;

  @ApiPropertyOptional({ description: 'Field group for UI grouping within section' })
  fieldGroup?: string;

  @ApiPropertyOptional({ description: 'Display order within section' })
  displayOrder?: number;
}

/**
 * A section in the report with its resolved fields.
 */
export class ReportSectionDto {
  @ApiProperty({ description: 'Section ID' })
  id: string;

  @ApiProperty({ description: 'Section title' })
  title: string;

  @ApiProperty({ description: 'Section order' })
  order: number;

  @ApiPropertyOptional({ description: 'Section type key from config (e.g. "about-property")' })
  sectionTypeKey?: string;

  @ApiProperty({ description: 'Resolved fields with display values', type: [ReportFieldDto] })
  fields: ReportFieldDto[];
}

/**
 * Complete report-ready data for PDF generation.
 */
export class ReportDataResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  id: string;

  @ApiProperty({ description: 'Survey title' })
  title: string;

  @ApiProperty({ description: 'Property address' })
  propertyAddress: string;

  @ApiPropertyOptional({ description: 'Survey status' })
  status?: string;

  @ApiPropertyOptional({ description: 'Survey type' })
  type?: string;

  @ApiPropertyOptional({ description: 'Job reference' })
  jobRef?: string;

  @ApiPropertyOptional({ description: 'Client name' })
  clientName?: string;

  @ApiProperty({ description: 'Created date' })
  createdAt: Date;

  @ApiProperty({ description: 'Updated date' })
  updatedAt: Date;

  @ApiProperty({ description: 'Ordered sections with resolved fields', type: [ReportSectionDto] })
  sections: ReportSectionDto[];
}
