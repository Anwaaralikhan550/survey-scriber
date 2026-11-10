// Client file (3), 10 Nov 2026: portrait photos printed landscape and
// signatures were stretched in the report.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/report_image.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('portrait stays portrait inside a landscape box', () async {
    final out = (await uprightImageWithin(await _png(600, 1200), maxWidth: 460, maxHeight: 360))!;
    expect(out.height, 360);
    expect(out.width, 180);
  });

  test('landscape fits by width', () async {
    final out = (await uprightImageWithin(await _png(1200, 600), maxWidth: 460, maxHeight: 360))!;
    expect(out.width, 460);
    expect(out.height, 230);
  });

  test('small images are not enlarged', () async {
    final out = (await uprightImageWithin(await _png(100, 50), maxWidth: 460, maxHeight: 360))!;
    expect((out.width, out.height), (100, 50));
  });

  test('camera rotation flag (EXIF 6) is applied: stored 80x40, shown upright 40x80', () async {
    final bytes = File('test/fixtures/exif_rotated_landscape_pixels.jpg').readAsBytesSync();
    final out = (await uprightImageWithin(bytes, maxWidth: 460, maxHeight: 360))!;
    expect(out.height, greaterThan(out.width));
  });

  test('fitInto keeps the shape', () {
    final img = ReportImage(Uint8List(0), 300, 600);
    final f = img.fitInto(4500000, 3375000);
    expect(f.height, 3375000);
    expect(f.width, closeTo(1687500, 1));
  });

  test('garbage bytes give null', () async {
    expect(await uprightImageWithin(Uint8List.fromList([1, 2, 3]), maxWidth: 10, maxHeight: 10), isNull);
  });
}
