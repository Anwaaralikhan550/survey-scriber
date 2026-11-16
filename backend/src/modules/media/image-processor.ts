import { BadRequestException } from '@nestjs/common';
import sharp, { type Metadata } from 'sharp';

export const PHOTO_LIMITS = {
  minSide: 16,
  maxSide: 12000,
  maxPixels: 100_000_000,
};

export interface ProcessedPhoto {
  buffer: Buffer;
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp';
  extension: 'jpg' | 'png' | 'webp';
  width: number;
  height: number;
}

const FORMATS = {
  jpeg: { mimeType: 'image/jpeg', extension: 'jpg' },
  png: { mimeType: 'image/png', extension: 'png' },
  webp: { mimeType: 'image/webp', extension: 'webp' },
} as const;

/**
 * Decode the photo for real, check what it is and how big it is, turn it upright and re-encode it without
 * metadata (spec section 9: file signature, dimensions, EXIF/GPS removal). Anything that does not decode
 * as the format it claims is refused, so a renamed script or a truncated file never reaches storage.
 * Vector annotations from the app are separate data and are not touched.
 */
export async function processPhoto(input: Buffer, declaredMime: string): Promise<ProcessedPhoto> {
  let meta: Metadata;
  try {
    meta = await sharp(input, { limitInputPixels: PHOTO_LIMITS.maxPixels, failOn: 'error' }).metadata();
  } catch {
    throw new BadRequestException('The file is not a valid image');
  }
  const format = meta.format as keyof typeof FORMATS | undefined;
  if (!format || !(format in FORMATS)) throw new BadRequestException('Only JPEG, PNG and WebP photos are accepted');
  if (FORMATS[format].mimeType !== declaredMime) throw new BadRequestException('File content does not match the declared file type');

  // EXIF orientation 5-8 swaps width and height once the photo is turned upright.
  const turned = (meta.orientation ?? 1) >= 5;
  const width = (turned ? meta.height : meta.width) ?? 0;
  const height = (turned ? meta.width : meta.height) ?? 0;
  if (width < PHOTO_LIMITS.minSide || height < PHOTO_LIMITS.minSide) {
    throw new BadRequestException(`The photo is too small (at least ${PHOTO_LIMITS.minSide} pixels each side)`);
  }
  if (width > PHOTO_LIMITS.maxSide || height > PHOTO_LIMITS.maxSide) {
    throw new BadRequestException(`The photo is too large (at most ${PHOTO_LIMITS.maxSide} pixels each side)`);
  }

  try {
    let pipeline = sharp(input, { limitInputPixels: PHOTO_LIMITS.maxPixels, failOn: 'error' }).rotate(); // upright, metadata dropped
    if (format === 'jpeg') pipeline = pipeline.jpeg({ quality: 90 });
    else if (format === 'png') pipeline = pipeline.png();
    else pipeline = pipeline.webp({ quality: 90 });
    const { data, info } = await pipeline.toBuffer({ resolveWithObject: true });
    return { buffer: data, mimeType: FORMATS[format].mimeType, extension: FORMATS[format].extension, width: info.width, height: info.height };
  } catch {
    throw new BadRequestException('The photo could not be read. It may be damaged.');
  }
}
