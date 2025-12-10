import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/face_recognition_service.dart';
import '../../../core/localization_service.dart';

class FaceRecognitionPage extends ConsumerStatefulWidget {
  const FaceRecognitionPage({super.key});
  @override
  ConsumerState<FaceRecognitionPage> createState() =>
      _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends ConsumerState<FaceRecognitionPage> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  Map<String, dynamic>? _matchResult;
  bool _isProcessing = false;
  Future<void> _captureAndMatch() async {
    setState(() {
      _isProcessing = true;
      _matchResult = null;
    });
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }
      setState(() => _imagePath = image.path);
      final service = ref.read(faceRecognitionServiceProvider.notifier);
      final result = await service.matchFace(image);
      setState(() {
        _matchResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'face_title'))),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureAndMatch,
                icon: const Icon(Icons.face),
                label: Text(_isProcessing
                    ? tr(ref, 'face_processing')
                    : tr(ref, 'face_btn_capture')),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16))),
            const SizedBox(height: 24),
            if (_imagePath != null)
              Image.file(File(_imagePath!), height: 300, fit: BoxFit.contain),
            const SizedBox(height: 16),
            if (_isProcessing) const Center(child: CircularProgressIndicator()),
            if (_matchResult != null)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(ref, 'face_result'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                '${tr(ref, 'face_matched')} ${_matchResult!['matched'] ?? false}'),
                            if (_matchResult!['person_name'] != null)
                              Text(
                                  '${tr(ref, 'face_name')} ${_matchResult!['person_name']}'),
                            if (_matchResult!['similarity'] != null)
                              Text(
                                  '${tr(ref, 'face_sim')} ${((_matchResult!['similarity'] as double) * 100).toStringAsFixed(2)}%')
                          ])))
          ])),
    );
  }
}
