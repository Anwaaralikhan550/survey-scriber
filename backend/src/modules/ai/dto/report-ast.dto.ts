import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type ReportAstParagraphSource = 'excel' | 'rule' | 'user';

export interface ReportAstParagraph {
  id: string;
  text: string;
  source: ReportAstParagraphSource;
  tags?: string[];
  groupKey?: string;
}

export interface ConditionRatingBlock {
  label: 'Condition Rating';
  value: string;
  sourceFieldKey?: string;
}

export interface ReportSectionAst {
  sectionId: string;
  sectionType: string;
  title: string;
  conditionRating?: ConditionRatingBlock;
  limitations: ReportAstParagraph[];
  defaultParagraphs: ReportAstParagraph[];
  dynamicPhrases: ReportAstParagraph[];
  remarks: ReportAstParagraph[];
  otherConsiderations?: ReportAstParagraph[];
}

export interface ReportAstMetadata {
  reportTitle: 'Home Survey Inspection Report';
  surveyId?: string;
  propertyAddress?: string;
  propertyType?: string;
  generatedAtIso: string;
}

export interface ReportAstPayload {
  schemaVersion: '2.0';
  metadata: ReportAstMetadata;
  sectionOrder: string[];
  sections: ReportSectionAst[];
}

export class ReportAstParagraphDto {
  @ApiProperty({ description: 'Stable paragraph identifier' })
  id: string;

  @ApiProperty({ description: 'Paragraph content text' })
  text: string;

  @ApiProperty({ enum: ['excel', 'rule', 'user'] })
  source: ReportAstParagraphSource;

  @ApiPropertyOptional({
    description: 'Semantic tags used by renderers/grouping',
    type: [String],
  })
  tags?: string[];

  @ApiPropertyOptional({
    description: 'Logical grouping key for merged paragraphs',
  })
  groupKey?: string;
}

export class ConditionRatingBlockDto {
  @ApiProperty({ example: 'Condition Rating' })
  label: 'Condition Rating';

  @ApiProperty({ description: 'Condition rating value as captured' })
  value: string;

  @ApiPropertyOptional({ description: 'Source field key' })
  sourceFieldKey?: string;
}

export class ReportSectionAstDto {
  @ApiProperty()
  sectionId: string;

  @ApiProperty()
  sectionType: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional({ type: ConditionRatingBlockDto })
  conditionRating?: ConditionRatingBlockDto;

  @ApiProperty({ type: [ReportAstParagraphDto] })
  limitations: ReportAstParagraphDto[];

  @ApiProperty({ type: [ReportAstParagraphDto] })
  defaultParagraphs: ReportAstParagraphDto[];

  @ApiProperty({ type: [ReportAstParagraphDto] })
  dynamicPhrases: ReportAstParagraphDto[];

  @ApiProperty({ type: [ReportAstParagraphDto] })
  remarks: ReportAstParagraphDto[];

  @ApiPropertyOptional({ type: [ReportAstParagraphDto] })
  otherConsiderations?: ReportAstParagraphDto[];
}

export class ReportAstMetadataDto {
  @ApiProperty({
    example: 'Home Survey Inspection Report',
  })
  reportTitle: 'Home Survey Inspection Report';

  @ApiPropertyOptional()
  surveyId?: string;

  @ApiPropertyOptional()
  propertyAddress?: string;

  @ApiPropertyOptional()
  propertyType?: string;

  @ApiProperty({ description: 'ISO timestamp for payload generation' })
  generatedAtIso: string;
}

export class ReportAstPayloadDto {
  @ApiProperty({ example: '2.0' })
  schemaVersion: '2.0';

  @ApiProperty({ type: ReportAstMetadataDto })
  metadata: ReportAstMetadataDto;

  @ApiProperty({ type: [String] })
  sectionOrder: string[];

  @ApiProperty({ type: [ReportSectionAstDto] })
  sections: ReportSectionAstDto[];
}
