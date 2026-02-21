#!/bin/bash

# ============================================
# SurveyScriber - Production Build Script
# ============================================
# Builds the Flutter app for production deployment
# with the production VPS backend URL
# ============================================

set -e

echo "=========================================="
echo "  SurveyScriber Production Build"
echo "=========================================="
echo ""

# Configuration
PRODUCTION_API_URL="http://148.113.203.250:3000/api/v1"

echo "🔧 Configuration:"
echo "  API URL: $PRODUCTION_API_URL"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get
echo "✓ Clean complete"
echo ""

# Build Android APK
echo "📦 Building Android APK (Production)..."
flutter build apk --release --dart-define=API_BASE_URL=$PRODUCTION_API_URL
echo "✓ Android APK built successfully"
echo ""

# Build Android App Bundle (for Play Store)
echo "📦 Building Android App Bundle (Production)..."
flutter build appbundle --release --dart-define=API_BASE_URL=$PRODUCTION_API_URL
echo "✓ Android App Bundle built successfully"
echo ""

echo "=========================================="
echo "  ✅ Production Build Complete!"
echo "=========================================="
echo ""
echo "📍 Output files:"
echo "  APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  AAB: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📱 Install APK on device:"
echo "  flutter install --release"
echo "  or manually: adb install build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "🚀 App configured for:"
echo "  Backend: $PRODUCTION_API_URL"
echo ""
