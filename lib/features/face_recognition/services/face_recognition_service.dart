import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/edge_function_service.dart';

part 'face_recognition_service.g.dart';

@riverpod
class FaceRecognitionService extends _$FaceRecognitionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  int _inputSize = 112;

  @override
  Future<bool> build() async {
    if (_isInitialized) return true;
    return await initialize();
  }

  Future<bool> initialize() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
          'assets/models/face_recognition.tflite',
          options: options);

      var inputShape = _interpreter!.getInputTensor(0).shape;
      if (inputShape.length > 2) {
        _inputSize = inputShape[1];
      }
      print("Face Model Loaded. Input Size: $_inputSize");

      _isInitialized = true;
      return true;
    } catch (e) {
      print("Face Model Error: $e");
      return false;
    }
  }

  Future<List<double>> extractEmbedding(XFile imageFile) async {
    if (!_isInitialized) await initialize();
    if (_interpreter == null) return [];

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) return [];

      img.Image resized =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      var input = List.generate(
          1,
          (i) => List.generate(
              _inputSize,
              (y) => List.generate(_inputSize, (x) {
                    var pixel = resized.getPixel(x, y);
                    return [
                      (pixel.r.toDouble() - 128) / 128.0,
                      (pixel.g.toDouble() - 128) / 128.0,
                      (pixel.b.toDouble() - 128) / 128.0
                    ];
                  })));

      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var outputSize = outputShape.last;
      var output = List.filled(1 * outputSize, 0.0).reshape([1, outputSize]);

      _interpreter!.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      return _l2Normalize(embedding);
    } catch (e) {
      print("Extraction Failed: $e");
      return [];
    }
  }

  List<double> _l2Normalize(List<double> embedding) {
    var sum = 0.0;
    for (var x in embedding) {
      sum += x * x;
    }
    var norm = sqrt(sum);
    return embedding.map((x) => x / norm).toList();
  }

  Future<Map<String, dynamic>> matchFace(XFile imageFile) async {
    try {
      final embedding = await extractEmbedding(imageFile);
      if (embedding.isEmpty)
        return {'matched': false, 'error': 'Wajah tidak jelas'};

      final matchResult = await EdgeFunctionService.faceMatch(
        embedding: embedding,
      );
      return matchResult;
    } catch (e) {
      return {'matched': false, 'error': e.toString()};
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
