import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/object_detection_service.dart';
import '../widgets/detection_overlay.dart';
import '../../../core/localization_service.dart';

class ObjectDetectionPage extends ConsumerStatefulWidget {
  const ObjectDetectionPage({super.key});
  @override
  ConsumerState<ObjectDetectionPage> createState() =>
      _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends ConsumerState<ObjectDetectionPage> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  List<DetectionResult> _detections = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
      _startDetection();
    }
  }

  void _startDetection() {
    _isDetecting = true;
    _cameraController?.startImageStream((image) async {
      if (!_isDetecting) return;
      final service = ref.read(objectDetectionServiceProvider.notifier);
      final results = await service.detectObjects(image);
      if (mounted) setState(() => _detections = results);
    });
  }

  @override
  void dispose() {
    _isDetecting = false;
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // Listen Language Change
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: CircularProgressIndicator(color: Colors.greenAccent)));
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        SizedBox(
            width: size.width,
            height: size.height,
            child: CameraPreview(_cameraController!)),
        DetectionOverlay(
            detections: _detections,
            previewSize: Size(_cameraController!.value.previewSize!.height,
                _cameraController!.value.previewSize!.width),
            screenSize: size),
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.3), width: 2)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: const EdgeInsets.only(
                              top: 40, left: 20, right: 20, bottom: 10),
                          color: Colors.black.withOpacity(0.6),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.arrow_back_ios,
                                        color: Colors.greenAccent),
                                    onPressed: () => Navigator.pop(context)),
                                Text(tr(ref, 'obj_title'),
                                    style: GoogleFonts.orbitron(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2)),
                                const Icon(Icons.radar,
                                    color: Colors.greenAccent)
                              ])),
                      Container(
                          padding: const EdgeInsets.all(20),
                          color: Colors.black.withOpacity(0.6),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _hudStat(tr(ref, 'obj_fps'), "60"),
                                _hudStat(tr(ref, 'obj_count'),
                                    "${_detections.length}"),
                                _hudStat(tr(ref, 'obj_status'),
                                    tr(ref, 'obj_scanning'))
                              ]))
                    ]))),
        Center(
            child: Icon(Icons.add,
                color: Colors.greenAccent.withOpacity(0.5), size: 40)),
      ]),
    );
  }

  Widget _hudStat(String label, String value) => Column(children: [
        Text(label,
            style: GoogleFonts.orbitron(color: Colors.green, fontSize: 10)),
        Text(value,
            style: GoogleFonts.orbitron(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
      ]);
}
