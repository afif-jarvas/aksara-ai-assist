import 'dart:math';
import 'package:flutter/material.dart';
// Import Service untuk mengambil definisi DetectionResult
import '../services/object_detection_service.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size previewSize;
  final Size screenSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: detections.map((result) {
        return _buildBox(context, result);
      }).toList(),
    );
  }

  Widget _buildBox(BuildContext context, DetectionResult result) {
    var screenRatio = screenSize.height / screenSize.width;
    var previewRatio = previewSize.height / previewSize.width;

    double scaleWidth, scaleHeight, x, y, w, h;

    if (screenRatio > previewRatio) {
      // Layar lebih tinggi dari preview
      scaleHeight = screenSize.height;
      scaleWidth = screenSize.height / previewRatio;

      var difW = (scaleWidth - screenSize.width) / scaleWidth;
      x = (result.x - difW / 2) * scaleWidth;
      w = result.width * scaleWidth;

      if (result.x < difW / 2) {
        w -= (difW / 2 - result.x) * scaleWidth;
      }

      y = result.y * scaleHeight;
      h = result.height * scaleHeight;
    } else {
      // Layar lebih lebar dari preview
      scaleHeight = screenSize.width * previewRatio;
      scaleWidth = screenSize.width;

      var difH = (scaleHeight - screenSize.height) / scaleHeight;
      x = result.x * scaleWidth;
      w = result.width * scaleWidth;

      y = (result.y - difH / 2) * scaleHeight;
      h = result.height * scaleHeight;

      if (result.y < difH / 2) {
        h -= (difH / 2 - result.y) * scaleHeight;
      }
    }

    // Desain Kotak Sci-Fi
    return Positioned(
      left: max(0, x),
      top: max(0, y),
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 2.0),
          color: Colors.greenAccent.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.greenAccent.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '${result.label} ${(result.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
