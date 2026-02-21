// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/app/widgets/app_logo.dart';

/// Integration test to generate app icon PNG files from the logo widget.
///
/// Run with: flutter test integration_test/generate_icon_test.dart
///
/// This will generate:
/// - assets/icons/app_icon_1024.png (for flutter_launcher_icons)
/// - assets/icons/icon_foreground.png (for adaptive icon foreground)
void main() {
  testWidgets('Generate app icon PNG files', (tester) async {
    // Ensure the directory exists
    final iconsDir = Directory('assets/icons');
    if (!iconsDir.existsSync()) {
      iconsDir.createSync(recursive: true);
    }

    // Generate 1024x1024 full icon (with white background)
    print('Generating app_icon_1024.png...');
    await _generateIconPng(
      tester,
      size: 1024,
      backgroundColor: Colors.white,
      outputPath: 'assets/icons/app_icon_1024.png',
    );

    // Generate foreground-only icon for adaptive icons
    print('Generating icon_foreground.png...');
    await _generateIconPng(
      tester,
      size: 1024,
      backgroundColor: Colors.transparent,
      outputPath: 'assets/icons/icon_foreground.png',
    );

    print('');
    print('Icon generation complete!');
    print('');
    print('Now run: dart run flutter_launcher_icons');
    print('to generate all platform-specific icons.');
  });
}

Future<void> _generateIconPng(
  WidgetTester tester, {
  required int size,
  required Color backgroundColor,
  required String outputPath,
}) async {
  // Create a repaint boundary key
  final boundaryKey = GlobalKey();

  // Build the widget
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: boundaryKey,
        child: Container(
          width: size.toDouble(),
          height: size.toDouble(),
          color: backgroundColor,
          child: Center(
            child: Padding(
              // Add padding for safe zone (adaptive icons need ~18% padding)
              padding: EdgeInsets.all(size * 0.15),
              child: AppLogo(size: size * 0.7),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Capture the image
  final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    final bytes = byteData.buffer.asUint8List();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    print('  Saved: $outputPath (${bytes.length} bytes)');
  }
}
