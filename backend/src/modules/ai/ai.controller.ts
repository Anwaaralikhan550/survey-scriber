import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Headers,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { UserRole } from '@prisma/client';
import { AiService } from './ai.service';
import { JwtAuthGuard, RolesGuard } from '../auth/guards';
import { CurrentUser, Public } from '../auth/decorators';
import { Roles } from '../auth/decorators/roles.decorator';
import {
  GenerateReportDto,
  GenerateRecommendationsDto,
  GenerateRiskSummaryDto,
  ConsistencyCheckDto,
  PhotoTagsDto,
  AiReportResponseDto,
  AiRecommendationsResponseDto,
  AiRiskSummaryResponseDto,
  AiConsistencyResponseDto,
  AiPhotoTagsResponseDto,
  AiStatusResponseDto,
} from './dto';

interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  organization?: string;
}

@ApiTags('AI')
@Controller('ai')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
@ApiBearerAuth()
export class AiController {
  private readonly logger = new Logger(AiController.name);

  constructor(private readonly aiService: AiService) {}

  @Public()
  @Get('status')
  @ApiOperation({ summary: 'Check AI service availability' })
  @ApiResponse({ status: 200, type: AiStatusResponseDto })
  async getStatus(): Promise<AiStatusResponseDto> {
    return this.aiService.getPublicStatus();
  }

  @Post('report')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 5 } }) // 5 requests per minute for reports
  @ApiOperation({
    summary: 'Generate AI narrative report sections',
    description: 'Generates RICS-style narrative text for survey report sections based on inspection data.',
  })
  @ApiResponse({ status: 200, type: AiReportResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 503, description: 'AI service unavailable or quota exceeded' })
  async generateReport(
    @Body() dto: GenerateReportDto,
    @CurrentUser() user: JwtPayload,
    @Headers('x-correlation-id') correlationId?: string,
  ): Promise<AiReportResponseDto> {
    const cid = correlationId || 'none';
    this.logger.log(`[cid=${cid}] Report request from user=${user.sub} survey=${dto.surveyId}`);
    const startTime = Date.now();

    try {
      const result = await this.aiService.generateReport(dto, {
        userId: user.sub,
        organization: user.organization,
      });
      this.logger.log(`[cid=${cid}] Report completed in ${Date.now() - startTime}ms`);
      return result;
    } catch (error) {
      this.logger.error(`[cid=${cid}] Report failed after ${Date.now() - startTime}ms: ${error}`);
      throw error;
    }
  }

  @Post('recommendations')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 10 } }) // 10 requests per minute
  @ApiOperation({
    summary: 'Generate repair recommendations from issues',
    description: 'Generates prioritized repair recommendations based on identified defects and issues.',
  })
  @ApiResponse({ status: 200, type: AiRecommendationsResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid input data or no issues provided' })
  @ApiResponse({ status: 503, description: 'AI service unavailable or quota exceeded' })
  async generateRecommendations(
    @Body() dto: GenerateRecommendationsDto,
    @CurrentUser() user: JwtPayload,
    @Headers('x-correlation-id') correlationId?: string,
  ): Promise<AiRecommendationsResponseDto> {
    const cid = correlationId || 'none';
    this.logger.log(`[cid=${cid}] Recommendations request from user=${user.sub} survey=${dto.surveyId}`);
    const startTime = Date.now();

    try {
      const result = await this.aiService.generateRecommendations(dto, {
        userId: user.sub,
        organization: user.organization,
      });
      this.logger.log(`[cid=${cid}] Recommendations completed in ${Date.now() - startTime}ms`);
      return result;
    } catch (error) {
      this.logger.error(`[cid=${cid}] Recommendations failed after ${Date.now() - startTime}ms: ${error}`);
      throw error;
    }
  }

  @Post('risk-summary')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @ApiOperation({
    summary: 'Generate client-friendly risk summary',
    description: 'Generates a plain-English risk summary suitable for property buyers/owners.',
  })
  @ApiResponse({ status: 200, type: AiRiskSummaryResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 503, description: 'AI service unavailable or quota exceeded' })
  async generateRiskSummary(
    @Body() dto: GenerateRiskSummaryDto,
    @CurrentUser() user: JwtPayload,
    @Headers('x-correlation-id') correlationId?: string,
  ): Promise<AiRiskSummaryResponseDto> {
    const cid = correlationId || 'none';
    this.logger.log(`[cid=${cid}] Risk summary request from user=${user.sub} survey=${dto.surveyId}`);
    const startTime = Date.now();

    try {
      const result = await this.aiService.generateRiskSummary(dto, {
        userId: user.sub,
        organization: user.organization,
      });
      this.logger.log(`[cid=${cid}] Risk summary completed in ${Date.now() - startTime}ms`);
      return result;
    } catch (error) {
      this.logger.error(`[cid=${cid}] Risk summary failed after ${Date.now() - startTime}ms: ${error}`);
      throw error;
    }
  }

  @Post('consistency-check')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @ApiOperation({
    summary: 'Check survey data consistency',
    description: 'Reviews survey data for completeness, contradictions, and compliance issues.',
  })
  @ApiResponse({ status: 200, type: AiConsistencyResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 503, description: 'AI service unavailable or quota exceeded' })
  async checkConsistency(
    @Body() dto: ConsistencyCheckDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<AiConsistencyResponseDto> {
    return this.aiService.checkConsistency(dto, {
      userId: user.sub,
      organization: user.organization,
    });
  }

  @Post('photo-tags')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 20 } }) // Higher limit for photo tagging
  @ApiOperation({
    summary: 'Generate photo tags and description',
    description: 'Analyzes a photo and returns suggested tags, section assignment, and description.',
  })
  @ApiResponse({ status: 200, type: AiPhotoTagsResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 503, description: 'AI service unavailable or quota exceeded' })
  async generatePhotoTags(
    @Body() dto: PhotoTagsDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<AiPhotoTagsResponseDto> {
    return this.aiService.generatePhotoTags(dto, {
      userId: user.sub,
      organization: user.organization,
    });
  }
}
