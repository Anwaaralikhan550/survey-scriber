import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
  Res,
  StreamableFile,
  BadRequestException,
} from '@nestjs/common';
import { sanitizeFilename } from '../../common/utils/sanitize-filename';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiParam,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { UserRole, MediaType } from '@prisma/client';
import { Response } from 'express';
import * as fs from 'fs';
import { MediaService } from './media.service';
import { UploadMediaDto, MediaResponseDto, DeleteMediaResponseDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

interface MulterFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

@ApiTags('Media')
@ApiBearerAuth('JWT-auth')
@Controller('media')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('upload')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @Throttle({ default: { limit: 30, ttl: 60000 } }) // SEC-L10: 30 uploads per minute (supports batch photo sync)
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload media file',
    description: 'Upload a photo, audio recording, or signature to a survey. File is stored locally and metadata is saved to database.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['surveyId', 'type', 'file'],
      properties: {
        surveyId: {
          type: 'string',
          format: 'uuid',
          description: 'Survey UUID to attach media to',
          example: '550e8400-e29b-41d4-a716-446655440000',
        },
        type: {
          type: 'string',
          enum: ['PHOTO', 'AUDIO', 'SIGNATURE'],
          description: 'Type of media being uploaded',
          example: 'PHOTO',
        },
        file: {
          type: 'string',
          format: 'binary',
          description: 'The file to upload',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Media uploaded successfully',
    type: MediaResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid file type or size' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async upload(
    @UploadedFile() file: MulterFile,
    @Body() dto: UploadMediaDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<MediaResponseDto> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    return this.mediaService.upload(
      dto.surveyId,
      dto.type as MediaType,
      {
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
        buffer: file.buffer,
      },
      user,
    );
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR, UserRole.MANAGER, UserRole.VIEWER)
  @ApiOperation({
    summary: 'Get media metadata',
    description: 'Retrieve metadata for a media file. Does not return the file itself.',
  })
  @ApiParam({
    name: 'id',
    description: 'Media UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Media metadata',
    type: MediaResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Media not found' })
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<MediaResponseDto> {
    return this.mediaService.findOne(id, user);
  }

  @Get(':id/file')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR, UserRole.MANAGER, UserRole.VIEWER)
  @ApiOperation({
    summary: 'Download media file',
    description: 'Stream the actual media file. Sets appropriate Content-Type header.',
  })
  @ApiParam({
    name: 'id',
    description: 'Media UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'File stream',
    content: {
      'application/octet-stream': {
        schema: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Media not found' })
  async getFile(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const fileInfo = await this.mediaService.getFilePath(id, user);

    res.set({
      'Content-Type': fileInfo.mimeType,
      'Content-Disposition': `inline; filename="${sanitizeFilename(fileInfo.fileName)}"`,
      // Cache headers for mobile client efficiency (media files are immutable once uploaded)
      'Cache-Control': 'private, max-age=86400, immutable',
      'ETag': `"${id}"`, // Media ID as ETag since content is immutable
    });

    const fileStream = fs.createReadStream(fileInfo.path);
    return new StreamableFile(fileStream);
  }

  @Delete(':id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({
    summary: 'Delete media',
    description: 'Hard delete a media file. Removes both the file from storage and the database record.',
  })
  @ApiParam({
    name: 'id',
    description: 'Media UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Media deleted successfully',
    type: DeleteMediaResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Media not found' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DeleteMediaResponseDto> {
    return this.mediaService.delete(id, user);
  }
}
