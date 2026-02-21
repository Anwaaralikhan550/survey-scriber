// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Exports the exact AppLogo widget (same as login screen) to PNG files
/// Run with: flutter run -t tool/export_logo.dart
void main() {
  runApp(const LogoExporterApp());
}

class LogoExporterApp extends StatelessWidget {
  const LogoExporterApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LogoExporter(),
    );
}

class LogoExporter extends StatefulWidget {
  const LogoExporter({super.key});

  @override
  State<LogoExporter> createState() => _LogoExporterState();
}

class _LogoExporterState extends State<LogoExporter> {
  final GlobalKey _logoKey = GlobalKey();
  bool _exported = false;

  @override
  void initState() {
    super.initState();
    // Export after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _exportLogo());
  }

  Future<void> _exportLogo() async {
    try {
      final boundary = _logoKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to assets
      final file = File('assets/icons/app_logo_exported.png');
      await file.writeAsBytes(pngBytes);

      setState(() => _exported = true);
      print('✅ Logo exported to: ${file.path}');
      print('   Size: ${image.width}x${image.height}');
    } catch (e) {
      print('❌ Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The exact same logo widget used on login screen
            RepaintBoundary(
              key: _logoKey,
              child: const _ExactLoginLogo(size: 1024),
            ),
            const SizedBox(height: 32),
            Text(
              _exported ? 'Logo Exported!' : 'Exporting...',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
}

/// EXACT copy of the login screen logo
/// This is the single source of truth
class _ExactLoginLogo extends StatelessWidget {
  const _ExactLoginLogo({required this.size});

  final double size;

  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color gradientEndColor = Color(0xFF162D4A);

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.55;
    final borderRadius = size * 0.27;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, gradientEndColor],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        // No shadow for app icon (clean edges)
      ),
      child: Icon(
        Icons.edit_document,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
