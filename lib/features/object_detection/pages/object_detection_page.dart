import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/localization_service.dart';
import '../services/object_detection_service.dart';
import '../widgets/detection_overlay.dart';

class ObjectDetectionPage extends ConsumerStatefulWidget {
  const ObjectDetectionPage({super.key});

  @override
  ConsumerState<ObjectDetectionPage> createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends ConsumerState<ObjectDetectionPage> {
  late ObjectDetectionService _detectionService;
  CameraController? _cameraController;
  List<DetectedObject> _detectedObjects = [];
  bool _isDetecting = false;
  CameraImage? _currentImage; // Frame terakhir untuk dianalisa
  int _sensorOrientation = 0;

  @override
  void initState() {
    super.initState();
    _detectionService = ObjectDetectionService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _sensorOrientation = firstCamera.sensorOrientation;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium, 
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((image) {
      _currentImage = image; // Selalu update frame terakhir
      if (_isDetecting) return;
      _processFrame(image);
    });

    setState(() {});
  }

  Future<void> _processFrame(CameraImage image) async {
    _isDetecting = true;
    // Object Detector (Kotak Hijau)
    final objects = await _detectionService.processImage(image, _sensorOrientation);
    if (mounted) {
      setState(() {
        _detectedObjects = objects;
      });
    }
    _isDetecting = false;
  }

  // --- TOMBOL SHUTTER DITEKAN ---
  void _onCapturePressed() async {
    if (_cameraController == null || _currentImage == null) return;
    
    // 1. Bekukan kamera
    await _cameraController!.pausePreview();

    // 2. Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    // 3. ANALISA DETAIL (Image Labeling)
    final detailedLabels = await _detectionService.analyzeImageLabels(_currentImage!, _sensorOrientation);

    // 4. Tutup Loading
    if (mounted) Navigator.pop(context);

    // 5. Tampilkan Hasil
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _buildResultSheet(detailedLabels),
      ).whenComplete(() {
        // Lanjutkan kamera setelah tutup
        _cameraController?.resumePreview();
      });
    }
  }

  Widget _buildResultSheet(List<String> labels) {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    
    // Filter label yang unik
    final distinctLabels = labels.toSet().toList();

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr(ref, 'obj_result_list'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black
            ),
          ),
          const SizedBox(height: 20),
          
          if (distinctLabels.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 60, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(tr(ref, 'obj_empty'), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: distinctLabels.length,
                itemBuilder: (context, index) {
                  final rawLabel = distinctLabels[index];
                  // --- TRANSLATE DI SINI ---
                  final translatedLabel = translateObject(ref, rawLabel);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.label_outline, color: Colors.blueAccent, size: 22),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama Objek (Bahasa User)
                            Text(
                              translatedLabel, 
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, 
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87
                              ),
                            ),
                            // Nama Asli (Jika berbeda, tampilkan kecil di bawahnya)
                            if (translatedLabel != rawLabel)
                              Text(
                                rawLabel,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 12, 
                                  color: Colors.grey
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detectionService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_cameraController!),
            ),
          ),
          CustomPaint(
            painter: DetectionOverlay(
              _detectedObjects,
              Size(
                _cameraController!.value.previewSize!.height,
                _cameraController!.value.previewSize!.width,
              ),
              InputImageRotation.rotation0deg,
              color: Colors.greenAccent,
            ),
            child: Container(),
          ),
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                GlassmorphicContainer(
                  width: 160, height: 40,
                  borderRadius: 20, blur: 10, alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(colors: [Colors.black54, Colors.black26]),
                  borderGradient: LinearGradient(colors: [Colors.white24, Colors.white10]),
                  child: Text(
                    tr(ref, 'obj_title'), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Positioned(
            bottom: 140, left: 20, right: 20,
            child: Center(
              child: Text(
                tr(ref, 'obj_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70, 
                  fontSize: 14, 
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)]
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onCapturePressed,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white24,
                    ),
                    child: Center(
                      child: Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(ref, 'obj_btn_capture'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}