/**
 * SurveyScriber App Icon Generator
 *
 * Generates high-quality PNG icons from the logo SVG for:
 * - Android launcher icons (all densities)
 * - Android adaptive icon foregrounds (all densities)
 * - iOS app icons (all sizes)
 * - Splash screen images
 * - Main logo PNG for Flutter app
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Logo SVG path (with transparent background)
const LOGO_SVG_PATH = path.join(__dirname, '..', 'assets', 'icons', 'surveyscriber_logo.svg');
const LOGO_PNG_PATH = path.join(__dirname, '..', 'assets', 'icons', 'surveyscriber_logo.png');

// Output directories
const ANDROID_RES = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');
const IOS_ASSETS = path.join(__dirname, '..', 'ios', 'Runner', 'Assets.xcassets');
const ASSETS_ICONS = path.join(__dirname, '..', 'assets', 'icons');

// Android icon sizes (density -> size in px)
const ANDROID_SIZES = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

// Android adaptive icon foreground sizes (108dp base)
const ANDROID_FOREGROUND_SIZES = {
  'drawable-mdpi': 108,
  'drawable-hdpi': 162,
  'drawable-xhdpi': 216,
  'drawable-xxhdpi': 324,
  'drawable-xxxhdpi': 432,
};

// iOS icon sizes
const IOS_SIZES = [
  { name: 'Icon-App-20x20@1x.png', size: 20 },
  { name: 'Icon-App-20x20@2x.png', size: 40 },
  { name: 'Icon-App-20x20@3x.png', size: 60 },
  { name: 'Icon-App-29x29@1x.png', size: 29 },
  { name: 'Icon-App-29x29@2x.png', size: 58 },
  { name: 'Icon-App-29x29@3x.png', size: 87 },
  { name: 'Icon-App-40x40@1x.png', size: 40 },
  { name: 'Icon-App-40x40@2x.png', size: 80 },
  { name: 'Icon-App-40x40@3x.png', size: 120 },
  { name: 'Icon-App-60x60@2x.png', size: 120 },
  { name: 'Icon-App-60x60@3x.png', size: 180 },
  { name: 'Icon-App-76x76@1x.png', size: 76 },
  { name: 'Icon-App-76x76@2x.png', size: 152 },
  { name: 'Icon-App-83.5x83.5@2x.png', size: 167 },
  { name: 'Icon-App-1024x1024@1x.png', size: 1024 },
];

async function generateIcons() {
  console.log('🎨 SurveyScriber Icon Generator\n');

  // Step 1: Convert SVG to high-res PNG (512x512 with transparent background)
  console.log('📐 Converting SVG to PNG...');
  const svgBuffer = fs.readFileSync(LOGO_SVG_PATH);

  // Generate main logo PNG at 512x512 with transparent background
  // Using high density (400 DPI) for maximum sharpness
  await sharp(svgBuffer, { density: 400 })
    .resize(512, 512, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      kernel: 'lanczos3' // Best quality resampling
    })
    .png({ quality: 100, compressionLevel: 9 })
    .toFile(LOGO_PNG_PATH);
  console.log('✓ Generated logo PNG:', LOGO_PNG_PATH);

  // Read the generated PNG for further processing
  const logoBuffer = fs.readFileSync(LOGO_PNG_PATH);
  const logoMetadata = await sharp(logoBuffer).metadata();
  console.log(`  Size: ${logoMetadata.width}x${logoMetadata.height}`);

  // Generate main icon at 1024x1024 with white background for app stores
  const mainIconPath = path.join(ASSETS_ICONS, 'app_icon_1024.png');
  const mainLogoSize = 820; // Slightly zoomed in
  const mainPadding = (1024 - mainLogoSize) / 2;

  const resizedMainLogo = await sharp(logoBuffer)
    .resize(mainLogoSize, mainLogoSize, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
    .toBuffer();

  await sharp({
    create: {
      width: 1024,
      height: 1024,
      channels: 4,
      background: { r: 255, g: 255, b: 255, alpha: 1 }
    }
  })
    .composite([{
      input: resizedMainLogo,
      top: Math.floor(mainPadding),
      left: Math.floor(mainPadding),
    }])
    .flatten({ background: { r: 255, g: 255, b: 255 } })
    .png({ quality: 100 })
    .toFile(mainIconPath);
  console.log('✓ Generated main icon:', mainIconPath);

  // Generate Android launcher icons (with white background)
  console.log('\n📱 Generating Android launcher icons...');
  for (const [folder, size] of Object.entries(ANDROID_SIZES)) {
    const outputDir = path.join(ANDROID_RES, folder);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const logoSize = Math.floor(size * 0.82); // Logo takes 82% of icon (zoomed in for balance)
    const padding = Math.floor((size - logoSize) / 2);

    // First resize the logo with high-quality resampling
    const resizedLogo = await sharp(logoBuffer)
      .resize(logoSize, logoSize, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 0 },
        kernel: 'lanczos3'
      })
      .toBuffer();

    // Create white background and composite the logo on top
    const outputPath = path.join(outputDir, 'ic_launcher.png');
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: { r: 255, g: 255, b: 255, alpha: 1 }
      }
    })
      .composite([{
        input: resizedLogo,
        top: padding,
        left: padding,
      }])
      .flatten({ background: { r: 255, g: 255, b: 255 } })
      .png({ quality: 100 })
      .toFile(outputPath);
    console.log(`  ✓ ${folder}/ic_launcher.png (${size}x${size})`);
  }

  // Generate Android adaptive icon foregrounds (transparent background, centered)
  console.log('\n🔷 Generating Android adaptive icon foregrounds...');
  for (const [folder, size] of Object.entries(ANDROID_FOREGROUND_SIZES)) {
    const outputDir = path.join(ANDROID_RES, folder);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // For adaptive icons, logo should be in the safe zone (68% of canvas for better zoom)
    const safeZoneSize = Math.floor(size * 0.68);
    const padding = Math.floor((size - safeZoneSize) / 2);

    const outputPath = path.join(outputDir, 'ic_launcher_foreground.png');
    await sharp(logoBuffer)
      .resize(safeZoneSize, safeZoneSize, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 0 },
        kernel: 'lanczos3'
      })
      .extend({
        top: padding,
        bottom: padding,
        left: padding,
        right: padding,
        background: { r: 255, g: 255, b: 255, alpha: 0 }
      })
      .png({ quality: 100, compressionLevel: 9 })
      .toFile(outputPath);
    console.log(`  ✓ ${folder}/ic_launcher_foreground.png (${size}x${size})`);
  }

  // Generate iOS icons (with white background, no transparency allowed)
  console.log('\n🍎 Generating iOS icons...');
  const iosOutputDir = path.join(IOS_ASSETS, 'AppIcon.appiconset');
  if (!fs.existsSync(iosOutputDir)) {
    fs.mkdirSync(iosOutputDir, { recursive: true });
  }

  for (const { name, size } of IOS_SIZES) {
    const logoSize = Math.floor(size * 0.82); // 82% for better zoom
    const padding = Math.floor((size - logoSize) / 2);

    const outputPath = path.join(iosOutputDir, name);

    // First resize the logo with high-quality resampling
    const resizedLogo = await sharp(logoBuffer)
      .resize(logoSize, logoSize, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 0 },
        kernel: 'lanczos3'
      })
      .toBuffer();

    // Create white background and composite the logo on top
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: { r: 255, g: 255, b: 255, alpha: 1 }
      }
    })
      .composite([{
        input: resizedLogo,
        top: padding,
        left: padding,
      }])
      .flatten({ background: { r: 255, g: 255, b: 255 } })
      .png({ quality: 100 })
      .toFile(outputPath);
    console.log(`  ✓ ${name} (${size}x${size})`);
  }

  // Generate splash screen images (with transparent background for Flutter splash)
  console.log('\n🚀 Generating splash screen images...');

  // Android splash - transparent background
  const drawableDir = path.join(ANDROID_RES, 'drawable');
  if (!fs.existsSync(drawableDir)) {
    fs.mkdirSync(drawableDir, { recursive: true });
  }

  const androidSplashPath = path.join(drawableDir, 'launch_image.png');
  await sharp(logoBuffer)
    .resize(512, 512, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
    .png({ quality: 100 })
    .toFile(androidSplashPath);
  console.log('  ✓ Android splash:', androidSplashPath);

  // iOS launch images - transparent background
  const iosLaunchDir = path.join(IOS_ASSETS, 'LaunchImage.imageset');
  if (!fs.existsSync(iosLaunchDir)) {
    fs.mkdirSync(iosLaunchDir, { recursive: true });
  }

  const launchSizes = [
    { name: 'LaunchImage.png', size: 512 },
    { name: 'LaunchImage@2x.png', size: 1024 },
    { name: 'LaunchImage@3x.png', size: 1024 },
  ];

  for (const { name, size } of launchSizes) {
    const outputPath = path.join(iosLaunchDir, name);
    await sharp(logoBuffer)
      .resize(size, size, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .png({ quality: 100 })
      .toFile(outputPath);
    console.log(`  ✓ ${name} (${size}x${size})`);
  }

  console.log('\n✅ All icons generated successfully!');
  console.log('\nNext steps:');
  console.log('1. Run: flutter pub get');
  console.log('2. Build and test the app');
}

generateIcons().catch(console.error);
