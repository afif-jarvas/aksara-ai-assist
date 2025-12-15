import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';
import '../services/face_recognition_service.dart';

class FaceEnrollmentPage extends ConsumerStatefulWidget {
  const FaceEnrollmentPage({super.key});

  @override
  ConsumerState<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends ConsumerState<FaceEnrollmentPage> {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  CameraController? _controller;
  
  final int _targetSamples = 10;
  List<List<double>> _embeddings = [];
  bool _isProcessing = false;
  String _instructionKey = "face_angle_center";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if(mounted) setState(() {});
  }

  void _captureSample() async {
    if (_controller == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _controller!.startImageStream((image) async {
        await _controller!.stopImageStream(); 

        final embedding = await _faceService.processImage(image, 270); 

        if (mounted) {
          if (embedding != null) {
            _embeddings.add(embedding);
            _updateProgress();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(ref, 'face_fail'))));
          }
          setState(() => _isProcessing = false);
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _updateProgress() async {
    int count = _embeddings.length;
    
    // Instruksi ganti posisi kepala
    if (count < 2) _instructionKey = "face_angle_center";
    else if (count < 4) _instructionKey = "face_angle_left";
    else if (count < 6) _instructionKey = "face_angle_right";
    else if (count < 8) _instructionKey = "face_angle_up";
    else _instructionKey = "face_angle_down";

    if (count >= _targetSamples) {
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (c) => Center(child: CircularProgressIndicator())
      );
      
      bool success = await _faceService.registerFace(_embeddings);
      
      if(mounted) {
        Navigator.pop(context); // Close loading
        if(success) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: Icon(Icons.check_circle, color: Colors.green, size: 50),
              content: Text(tr(ref, 'face_success'), style: TextStyle(color: Colors.black)),
              actions: [TextButton(onPressed: () {Navigator.pop(c); Navigator.pop(context);}, child: Text("OK"))],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving face data")));
        }
      }
    }
  }

  @override
  void dispose() {
    _faceService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          Center(
            child: Container(
              width: 280, height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), spreadRadius: 1000)]
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: GlassmorphicContainer(
              width: double.infinity, height: 260,
              borderRadius: 24, blur: 20, alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(colors: [Colors.black54, Colors.black87]),
              borderGradient: LinearGradient(colors: [Colors.white12, Colors.white10]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tr(ref, 'face_setup_title'), style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("${tr(ref, 'face_setup_step')} ${_embeddings.length + 1} / $_targetSamples", style: const TextStyle(color: Colors.white70)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: _embeddings.length / _targetSamples, color: Colors.greenAccent, minHeight: 8),
                    ),
                  ),
                  Text(tr(ref, _instructionKey), style: GoogleFonts.plusJakartaSans(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _captureSample,
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20), backgroundColor: Colors.white),
                    child: _isProcessing ? const CircularProgressIndicator() : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}