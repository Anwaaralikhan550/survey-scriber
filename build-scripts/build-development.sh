#!/bin/bash

# ============================================
# SurveyScriber - Development Build Script
# ============================================
# Builds the Flutter app for local development
# with localhost/emulator backend URL
# ============================================

set -e

echo "=========================================="
echo "  SurveyScriber Development Build"
echo "=========================================="
echo ""

# Configuration
DEVELOPMENT_API_URL="http://10.0.2.2:3000/api/v1"

echo "🔧 Configuration:"
echo "  API URL: $DEVELOPMENT_API_URL (Android Emulator)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get
echo "✓ Clean complete"
echo ""

# Build Android APK
echo "📦 Building Android APK (Development)..."
flutter build apk --debug --dart-define=API_BASE_URL=$DEVELOPMENT_API_URL
echo "✓ Android APK built successfully"
echo ""

echo "=========================================="
echo "  ✅ Development Build Complete!"
echo "=========================================="
echo ""
echo "📍 Output files:"
echo "  APK: build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "📱 Install APK on device:"
echo "  flutter install"
echo "  or manually: adb install build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "🚀 App configured for:"
echo "  Backend: $DEVELOPMENT_API_URL"
echo ""
echo "💡 For physical device testing:"
echo "  Find your computer's IP address and run:"
echo "  flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api/v1"
echo ""
