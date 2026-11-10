import 'dart:typed_data';
import 'dart:ui' as ui;

/// An image ready to place in a report: upright, shape kept, and its size.
class ReportImage {
  const ReportImage(this.bytes, this.width, this.height);

  /// PNG bytes.
  final Uint8List bytes;
  final int width;
  final int height;

  /// Size that fits a [boxWidth] x [boxHeight] box without changing shape.
  ({double width, double height}) fitInto(double boxWidth, double boxHeight) {
    final scale = [boxWidth / width, boxHeight / height]
        .reduce((a, b) => a < b ? a : b);
    return (width: width * scale, height: height * scale);
  }
}

/// Decodes [input] (the phone's camera orientation applied by the platform
/// decoder) and shrinks it to fit within [maxWidth] x [maxHeight] keeping its
/// shape. Never enlarges. Returns null when the bytes cannot be decoded.
///
/// Client file (3), 10 Nov 2026: portrait photos were squashed into a
/// landscape box and signatures were stretched, because both a target width
/// and height were forced on the decoder.
Future<ReportImage?> uprightImageWithin(
  Uint8List input, {
  required int maxWidth,
  required int maxHeight,
}) async {
  Future<ui.Image> decode({int? width, int? height}) async {
    final codec = await ui.instantiateImageCodec(
      input,
      targetWidth: width,
      targetHeight: height,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  try {
    var image = await decode(width: maxWidth);
    if (image.height > maxHeight) {
      image.dispose();
      image = await decode(height: maxHeight);
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = data == null
        ? null
        : ReportImage(data.buffer.asUint8List(), image.width, image.height);
    image.dispose();
    return result;
  } catch (_) {
    return null;
  }
}
