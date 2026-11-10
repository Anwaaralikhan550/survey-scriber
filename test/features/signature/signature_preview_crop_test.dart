// Client file (3), 10 Nov 2026: "Captured signature poor resolution and not
// centralised in the box". The saved PNG is cropped to the ink and drawn at 3x.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/signature/domain/entities/signature_item.dart';
import 'package:survey_scriber/features/signature/presentation/providers/signature_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('sig_crop_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tmp.path,
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a small signature in a corner of a big pad becomes a tight, 3x image', () async {
    final service = SignaturePreviewService.instance;
    await service.init();
    // Ink spans x 10..110 and y 10..40 on a 400 x 200 pad.
    final path = await service.savePreview(
      signatureId: 't1',
      strokes: const [
        SignatureStroke(points: [
          SignaturePoint(x: 10, y: 10),
          SignaturePoint(x: 110, y: 40),
        ]),
      ],
      canvasSize: const ui.Size(400, 200),
    );
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    // (100 + 2.5 + 2 * 20) x (30 + 2.5 + 2 * 20) points, times 3.
    expect(image.width, (142.5 * 3).ceil());
    expect(image.height, (72.5 * 3).ceil());
  });

  test('no ink: the pad size is kept', () async {
    final service = SignaturePreviewService.instance;
    await service.init();
    final path = await service.savePreview(
      signatureId: 't2',
      strokes: const [],
      canvasSize: const ui.Size(300, 100),
    );
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    expect((image.width, image.height), (900, 300));
  });
}
