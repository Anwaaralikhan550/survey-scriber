import {
  IsString,
  IsObject,
  IsArray,
  IsOptional,
  IsBoolean,
  ValidateNested,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportAstPayloadDto } from './report-ast.dto';

// ============================================
// Request DTOs
// ============================================

export class SectionAnswersDto {
  @ApiProperty({ description: 'Section ID' })
  @IsString()
  @MaxLength(255)
  sectionId: string;

  @ApiProperty({ description: 'Section type (e.g., aboutProperty, externalCondition)' })
  @IsString()
  @MaxLength(255)
  sectionType: string;

  @ApiProperty({ description: 'Section title' })
  @IsString()
  @MaxLength(500)
  title: string;

  @ApiProperty({ description: 'Key-value pairs of field answers' })
  @IsObject()
  answers: Record<string, string>;
}

export class IssueDto {
  @ApiProperty({ description: 'Issue ID' })
  @IsString()
  @MaxLength(255)
  id: string;

  @ApiProperty({ description: 'Issue title' })
  @IsString()
  @MaxLength(500)
  title: string;

  @ApiPropertyOptional({ description: 'Issue category' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  category?: string;

  @ApiPropertyOptional({ description: 'Issue severity' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  severity?: string;

  @ApiPropertyOptional({ description: 'Location in property' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  location?: string;

  @ApiPropertyOptional({ description: 'Issue description' })
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;
}

export class GenerateReportDto {
  @ApiProperty({ description: 'Survey ID' })
  @IsString()
  @MaxLength(255)
  surveyId: string;

  @ApiProperty({ description: 'Property address' })
  @IsString()
  @MaxLength(1000)
  propertyAddress: string;

  @ApiPropertyOptional({ description: 'Property type' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  propertyType?: string;

  @ApiProperty({ description: 'Survey sections with answers', type: [SectionAnswersDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionAnswersDto)
  sections: SectionAnswersDto[];

  @ApiPropertyOptional({ description: 'List of issues/defects', type: [IssueDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IssueDto)
  issues?: IssueDto[];

  @ApiPropertyOptional({ description: 'Skip cache and force regeneration' })
  @IsOptional()
  @IsBoolean()
  skipCache?: boolean;
}

export class GenerateRecommendationsDto {
  @ApiProperty({ description: 'Survey ID' })
  @IsString()
  @MaxLength(255)
  surveyId: string;

  @ApiProperty({ description: 'Property address' })
  @IsString()
  @MaxLength(1000)
  propertyAddress: string;

  @ApiPropertyOptional({ description: 'Property type' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  propertyType?: string;

  @ApiPropertyOptional({ description: 'List of issues/defects (required if sections not provided)', type: [IssueDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IssueDto)
  issues?: IssueDto[];

  @ApiPropertyOptional({ description: 'Survey sections with answers (used when issues not provided)', type: [SectionAnswersDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionAnswersDto)
  sections?: SectionAnswersDto[];

  @ApiPropertyOptional({ description: 'Skip cache and force regeneration' })
  @IsOptional()
  @IsBoolean()
  skipCache?: boolean;
}

export class GenerateRiskSummaryDto {
  @ApiProperty({ description: 'Survey ID' })
  @IsString()
  surveyId: string;

  @ApiProperty({ description: 'Property address' })
  @IsString()
  propertyAddress: string;

  @ApiPropertyOptional({ description: 'Property type' })
  @IsOptional()
  @IsString()
  propertyType?: string;

  @ApiProperty({ description: 'Survey sections with answers', type: [SectionAnswersDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionAnswersDto)
  sections: SectionAnswersDto[];

  @ApiPropertyOptional({ description: 'List of issues/defects', type: [IssueDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IssueDto)
  issues?: IssueDto[];

  @ApiPropertyOptional({ description: 'Skip cache and force regeneration' })
  @IsOptional()
  @IsBoolean()
  skipCache?: boolean;
}

export class ConsistencyCheckDto {
  @ApiProperty({ description: 'Survey ID' })
  @IsString()
  surveyId: string;

  @ApiProperty({ description: 'Survey sections with answers', type: [SectionAnswersDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionAnswersDto)
  sections: SectionAnswersDto[];

  @ApiPropertyOptional({ description: 'List of issues/defects', type: [IssueDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IssueDto)
  issues?: IssueDto[];

  @ApiPropertyOptional({ description: 'Skip cache and force regeneration' })
  @IsOptional()
  @IsBoolean()
  skipCache?: boolean;
}

export class PhotoTagsDto {
  @ApiProperty({ description: 'Survey ID' })
  @IsString()
  surveyId: string;

  @ApiProperty({ description: 'Photo ID' })
  @IsString()
  photoId: string;

  @ApiProperty({ description: 'Base64 encoded image or URL' })
  @IsString()
  imageData: string;

  @ApiPropertyOptional({ description: 'Existing caption if any' })
  @IsOptional()
  @IsString()
  existingCaption?: string;

  @ApiPropertyOptional({ description: 'Context about the section this photo belongs to' })
  @IsOptional()
  @IsString()
  sectionContext?: string;

  @ApiPropertyOptional({ description: 'Skip cache and force regeneration' })
  @IsOptional()
  @IsBoolean()
  skipCache?: boolean;
}

// ============================================
// Response DTOs
// ============================================

export class SectionNarrativeDto {
  @ApiProperty({ description: 'Section ID' })
  sectionId: string;

  @ApiProperty({ description: 'Section type' })
  sectionType: string;

  @ApiProperty({ description: 'AI-generated narrative for this section' })
  narrative: string;

  @ApiProperty({ description: 'Confidence score 0-1' })
  confidence: number;
}

export class AiReportResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  surveyId: string;

  @ApiProperty({ description: 'Prompt version used' })
  promptVersion: string;

  @ApiProperty({ description: 'Section narratives', type: [SectionNarrativeDto] })
  sections: SectionNarrativeDto[];

  @ApiProperty({ description: 'Executive summary paragraph' })
  executiveSummary: string;

  @ApiProperty({ description: 'Whether result was from cache' })
  fromCache: boolean;

  @ApiProperty({ description: 'AI disclaimer text' })
  disclaimer: string;

  @ApiProperty({ description: 'Token usage' })
  usage: {
    inputTokens: number;
    outputTokens: number;
  };

  @ApiPropertyOptional({
    description: 'Structured report AST payload for native rendering pipelines',
    type: ReportAstPayloadDto,
  })
  ast?: ReportAstPayloadDto;
}

export class RecommendationDto {
  @ApiProperty({ description: 'Related issue ID' })
  issueId: string;

  @ApiProperty({ description: 'Priority: immediate, short_term, medium_term, long_term, monitor' })
  priority: string;

  @ApiProperty({ description: 'Recommended action' })
  action: string;

  @ApiProperty({ description: 'Reasoning for this recommendation' })
  reasoning: string;

  @ApiPropertyOptional({ description: 'Specialist type if referral needed' })
  specialistReferral?: string;

  @ApiProperty({ description: 'Estimated urgency explanation' })
  urgencyExplanation: string;
}

export class AiRecommendationsResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  surveyId: string;

  @ApiProperty({ description: 'Prompt version used' })
  promptVersion: string;

  @ApiProperty({ description: 'Recommendations list', type: [RecommendationDto] })
  recommendations: RecommendationDto[];

  @ApiProperty({ description: 'Whether result was from cache' })
  fromCache: boolean;

  @ApiProperty({ description: 'AI disclaimer text' })
  disclaimer: string;

  @ApiProperty({ description: 'Token usage' })
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
}

export class RiskItemDto {
  @ApiProperty({ description: 'Risk category' })
  category: string;

  @ApiProperty({ description: 'Risk level: high, medium, low' })
  level: string;

  @ApiProperty({ description: 'Description of the risk' })
  description: string;

  @ApiPropertyOptional({ description: 'Related section or issue IDs' })
  relatedIds?: string[];
}

export class RiskByCategoryDto {
  @ApiProperty({ description: 'Category name (Structural, Roof/Exterior, Plumbing, etc.)' })
  category: string;

  @ApiProperty({ description: 'Risk level for this category: high, medium, low' })
  risk: string;

  @ApiProperty({ description: 'Evidence from inspection data supporting this risk level' })
  evidence: string[];

  @ApiProperty({ description: 'What to verify or investigate next for this category' })
  verifyNext: string[];
}

export class AiRiskSummaryResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  surveyId: string;

  @ApiProperty({ description: 'Prompt version used' })
  promptVersion: string;

  @ApiProperty({ description: 'Overall risk level: high, medium, low' })
  overallRiskLevel: string;

  @ApiProperty({ description: 'Rationale lines explaining why this risk level was assigned' })
  overallRationale: string[];

  @ApiProperty({ description: 'Plain-English summary for clients (3-5 paragraphs)' })
  summary: string;

  @ApiProperty({ description: 'Key risk drivers (at least 12 items)' })
  keyRiskDrivers: string[];

  @ApiProperty({ description: 'Key risks identified', type: [RiskItemDto] })
  keyRisks: RiskItemDto[];

  @ApiProperty({ description: 'Key positives about the property' })
  keyPositives: string[];

  @ApiProperty({ description: 'Risk assessment by category (at least 8)', type: [RiskByCategoryDto] })
  riskByCategory: RiskByCategoryDto[];

  @ApiProperty({ description: 'Immediate actions (0-7 days)' })
  immediateActions: string[];

  @ApiProperty({ description: 'Short-term actions (1-3 months)' })
  shortTermActions: string[];

  @ApiProperty({ description: 'Long-term actions (3-12 months)' })
  longTermActions: string[];

  @ApiProperty({ description: 'Data gaps and missing assessments' })
  dataGaps: string[];

  @ApiProperty({ description: 'Whether result was from cache' })
  fromCache: boolean;

  @ApiProperty({ description: 'AI disclaimer text' })
  disclaimer: string;

  @ApiProperty({ description: 'Token usage' })
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
}

export class ConsistencyIssueDto {
  @ApiProperty({ description: 'Issue type: missing_data, contradiction, compliance_risk' })
  type: string;

  @ApiProperty({ description: 'Severity: high, medium, low' })
  severity: string;

  @ApiProperty({ description: 'Description of the issue' })
  description: string;

  @ApiPropertyOptional({ description: 'Section ID where issue was found' })
  sectionId?: string;

  @ApiPropertyOptional({ description: 'Field key if applicable' })
  fieldKey?: string;

  @ApiPropertyOptional({ description: 'Suggested fix' })
  suggestion?: string;
}

export class AiConsistencyResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  surveyId: string;

  @ApiProperty({ description: 'Prompt version used' })
  promptVersion: string;

  @ApiProperty({ description: 'Overall consistency score 0-100' })
  score: number;

  @ApiProperty({ description: 'Issues found', type: [ConsistencyIssueDto] })
  issues: ConsistencyIssueDto[];

  @ApiProperty({ description: 'Whether result was from cache' })
  fromCache: boolean;

  @ApiProperty({ description: 'AI disclaimer text' })
  disclaimer: string;

  @ApiProperty({ description: 'Token usage' })
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
}

export class PhotoTagDto {
  @ApiProperty({ description: 'Tag label' })
  label: string;

  @ApiProperty({ description: 'Confidence score 0-1' })
  confidence: number;
}

export class AiPhotoTagsResponseDto {
  @ApiProperty({ description: 'Survey ID' })
  surveyId: string;

  @ApiProperty({ description: 'Photo ID' })
  photoId: string;

  @ApiProperty({ description: 'Prompt version used' })
  promptVersion: string;

  @ApiProperty({ description: 'Generated tags', type: [PhotoTagDto] })
  tags: PhotoTagDto[];

  @ApiProperty({ description: 'Suggested section type for this photo' })
  suggestedSection: string;

  @ApiProperty({ description: 'AI-generated description of the photo' })
  description: string;

  @ApiProperty({ description: 'Whether result was from cache' })
  fromCache: boolean;

  @ApiProperty({ description: 'AI disclaimer text' })
  disclaimer: string;

  @ApiProperty({ description: 'Token usage' })
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
}

export class AiStatusResponseDto {
  @ApiProperty({ description: 'Whether AI service is available' })
  available: boolean;

  @ApiPropertyOptional({ description: 'Message if not available' })
  message?: string;

  @ApiPropertyOptional({ description: 'Daily quota remaining' })
  quotaRemaining?: number;

  @ApiPropertyOptional({ description: 'Daily quota limit' })
  quotaLimit?: number;

  @ApiPropertyOptional({ description: 'Selected PRO model' })
  selectedProModel?: string;

  @ApiPropertyOptional({ description: 'Selected FLASH model' })
  selectedFlashModel?: string;

  @ApiPropertyOptional({ description: 'Fallback PRO model (if primary was unavailable)' })
  fallbackProModel?: string;

  @ApiPropertyOptional({ description: 'Fallback FLASH model (if primary was unavailable)' })
  fallbackFlashModel?: string;

  @ApiPropertyOptional({ description: 'Last model validation timestamp' })
  lastValidationTime?: string;

  @ApiPropertyOptional({ description: 'Circuit breaker state (CLOSED, OPEN, HALF_OPEN)' })
  circuitBreakerState?: string;

  @ApiPropertyOptional({ description: 'Available models from API' })
  availableModels?: string[];
}
