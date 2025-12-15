import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class DetectionOverlay extends CustomPainter {
  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final Color color;

  DetectionOverlay(this.objects, this.absoluteImageSize, this.rotation, {this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = color;

    final Paint bgPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    for (final object in objects) {
      // Transformasi koordinat dari ukuran gambar kamera ke ukuran layar HP
      // Karena kamera biasanya dirotasi 90 derajat di portrait, width/height ditukar
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;

      final rect = Rect.fromLTRB(
        object.boundingBox.left * scaleX,
        object.boundingBox.top * scaleY,
        object.boundingBox.right * scaleX,
        object.boundingBox.bottom * scaleY,
      );

      // Gambar Kotak
      canvas.drawRect(rect, paint);

      // Gambar Label (jika ada hasil klasifikasi)
      if (object.labels.isNotEmpty) {
        final label = object.labels.first;
        // Tampilkan teks label dan confidence score (misal: Food 85%)
        final textSpan = TextSpan(
          text: "${label.text} ${(label.confidence * 100).toStringAsFixed(0)}%",
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Background hitam transparan untuk teks
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top - 25, textPainter.width + 10, 25),
          bgPaint,
        );

        // Gambar teks
        textPainter.paint(canvas, Offset(rect.left + 5, rect.top - 22));
      }
    }
  }

  @override
  bool shouldRepaint(DetectionOverlay oldDelegate) {
    return oldDelegate.objects != objects;
  }
}