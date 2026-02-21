/**
 * Android Icon Generator Script
 * Converts source image (PNG/SVG) to all required densities for Android
 *
 * Usage: node scripts/generate_android_icons.js [source_image_path]
 * Example: node scripts/generate_android_icons.js "C:\path\to\logo.png"
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const ANDROID_RES_PATH = 'android/app/src/main/res';
// Source can be PNG or SVG
const ICON_SOURCE_PATH = process.argv[2] || 'assets/icons/icon.svg';

// Android mipmap densities and their sizes
const MIPMAP_SIZES = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

// Splash screen / launch image size
const LAUNCH_IMAGE_SIZE = 512;

// App icon for flutter_launcher_icons (1024x1024)
const APP_ICON_SIZE = 1024;

// Adaptive icon foreground (432x432 for 108dp at 4x)
const FOREGROUND_SIZES = {
  'drawable-mdpi': 108,
  'drawable-hdpi': 162,
  'drawable-xhdpi': 216,
  'drawable-xxhdpi': 324,
  'drawable-xxxhdpi': 432,
};

async function generateIcons() {
  console.log('🎨 SurveyScriber Android Icon Generator\n');

  // Check if source image exists
  if (!fs.existsSync(ICON_SOURCE_PATH)) {
    console.error(`❌ Source image not found: ${ICON_SOURCE_PATH}`);
    process.exit(1);
  }

  const sourceBuffer = fs.readFileSync(ICON_SOURCE_PATH);
  console.log(`📄 Source: ${ICON_SOURCE_PATH}\n`);

  // 1. Generate mipmap launcher icons (for pre-Android 8 devices)
  console.log('📱 Generating mipmap launcher icons...');
  for (const [folder, size] of Object.entries(MIPMAP_SIZES)) {
    const outputPath = path.join(ANDROID_RES_PATH, folder, 'ic_launcher.png');

    // Ensure directory exists
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    await sharp(sourceBuffer)
      .resize(size, size, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 1 } })
      .flatten({ background: { r: 255, g: 255, b: 255 } })
      .png()
      .toFile(outputPath);

    console.log(`   ✅ ${folder}/ic_launcher.png (${size}x${size})`);
  }

  // 2. Generate adaptive icon foreground PNGs
  // For adaptive icons: canvas is 108dp, safe zone is 66dp (61%)
  // Using 73% provides optimal visual balance matching other app icons
  // Reduced from 78% (-5%) to match first SurveyScriber icon proportions
  const FOREGROUND_FILL = 0.73; // Logo fills 73% of 108dp canvas

  console.log('\n🔷 Generating adaptive icon foregrounds...');

  // Trim whitespace from source image first to get just the logo
  const trimmedBuffer = await sharp(sourceBuffer)
    .trim({ threshold: 10 }) // Remove near-white edges
    .toBuffer();

  const trimmedMeta = await sharp(trimmedBuffer).metadata();
  console.log(`   Trimmed source: ${trimmedMeta.width}x${trimmedMeta.height}`);

  for (const [folder, size] of Object.entries(FOREGROUND_SIZES)) {
    const outputPath = path.join(ANDROID_RES_PATH, folder, 'ic_launcher_foreground.png');

    // Ensure directory exists
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // Calculate icon size to fill target percentage of canvas
    const iconSize = Math.round(size * FOREGROUND_FILL);
    const padding = Math.round((size - iconSize) / 2);

    // Resize trimmed logo to fill the target area
    const resizedIcon = await sharp(trimmedBuffer)
      .resize(iconSize, iconSize, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .toBuffer();

    // Create transparent canvas and composite icon centered
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: { r: 255, g: 255, b: 255, alpha: 0 }
      }
    })
      .composite([{ input: resizedIcon, left: padding, top: padding }])
      .png()
      .toFile(outputPath);

    console.log(`   ✅ ${folder}/ic_launcher_foreground.png (${size}x${size}, icon: ${iconSize}px)`);
  }

  // 3. Generate splash screen launch image
  console.log('\n🌟 Generating splash screen image...');
  const launchImagePath = path.join(ANDROID_RES_PATH, 'drawable', 'launch_image.png');

  await sharp(sourceBuffer)
    .resize(LAUNCH_IMAGE_SIZE, LAUNCH_IMAGE_SIZE, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
    .png()
    .toFile(launchImagePath);

  console.log(`   ✅ drawable/launch_image.png (${LAUNCH_IMAGE_SIZE}x${LAUNCH_IMAGE_SIZE})`);

  // 4. Generate source PNG for flutter_launcher_icons
  console.log('\n📦 Generating source PNGs for flutter_launcher_icons...');

  const iconDir = 'assets/icons';
  if (!fs.existsSync(iconDir)) {
    fs.mkdirSync(iconDir, { recursive: true });
  }

  // Main app icon
  const appIconPath = path.join(iconDir, 'app_icon_1024.png');
  await sharp(sourceBuffer)
    .resize(APP_ICON_SIZE, APP_ICON_SIZE, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 1 } })
    .flatten({ background: { r: 255, g: 255, b: 255 } })
    .png()
    .toFile(appIconPath);
  console.log(`   ✅ ${appIconPath} (${APP_ICON_SIZE}x${APP_ICON_SIZE})`);

  // Adaptive foreground
  const foregroundPath = path.join(iconDir, 'icon_foreground.png');
  await sharp(sourceBuffer)
    .resize(APP_ICON_SIZE, APP_ICON_SIZE, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
    .png()
    .toFile(foregroundPath);
  console.log(`   ✅ ${foregroundPath} (${APP_ICON_SIZE}x${APP_ICON_SIZE})`);

  console.log('\n✨ All icons generated successfully!');
  console.log('\n📋 Next steps:');
  console.log('   1. Run: flutter pub run flutter_launcher_icons (optional)');
  console.log('   2. Rebuild the app: flutter build apk');
  console.log('   3. Install and verify the new icon on device');
}

generateIcons().catch(console.error);
