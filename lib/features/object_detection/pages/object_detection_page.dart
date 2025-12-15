import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization_service.dart';
import '../services/object_detection_service.dart';
import '../services/gemini_service.dart';
import '../widgets/detection_overlay.dart';

class ObjectDetectionPage extends ConsumerStatefulWidget {
  const ObjectDetectionPage({super.key});

  @override
  ConsumerState<ObjectDetectionPage> createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends ConsumerState<ObjectDetectionPage> {
  late ObjectDetectionService _trackingService;
  late GeminiObjectService _aiService;
  
  CameraController? _cameraController;
  List<DetectedObject> _detectedObjects = [];
  bool _isDetecting = false;
  int _sensorOrientation = 0;

  @override
  void initState() {
    super.initState();
    _trackingService = ObjectDetectionService();
    _aiService = GeminiObjectService();
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
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((image) {
      if (_isDetecting) return;
      _processTrackingFrame(image);
    });

    setState(() {});
  }

  Future<void> _processTrackingFrame(CameraImage image) async {
    _isDetecting = true;
    try {
      final objects = await _trackingService.processImage(image, _sensorOrientation);
      if (mounted) {
        setState(() => _detectedObjects = objects);
      }
    } catch (_) {}
    _isDetecting = false;
  }

  // --- UI LOADING (Multibahasa) ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: GlassmorphicContainer(
              width: 280,
              height: 180,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [const Color(0xFF1E1E2C).withOpacity(0.8), const Color(0xFF1E1E2C).withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.blueAccent,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr(ref, 'obj_ai_processing'), // "AI Sedang Menganalisa..."
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(ref, 'obj_ai_wait'), // "Mohon tunggu sebentar"
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCapturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    await _cameraController!.stopImageStream();
    
    if (!mounted) return;
    
    _showLoadingDialog();

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      // Kirim bahasa user saat ini ke service (jika diperlukan logic bahasa di service)
      // Tapi untuk saat ini prompt Gemini diatur manual di service. 
      // Jika ingin output JSON Gemini sesuai bahasa user, prompt di gemini_service.dart perlu disesuaikan dinamis.
      // Namun, output JSON biasanya kita minta konsisten, lalu UI yang menyesuaikan.
      // Untuk "Aksara Songsmith" kita pakai parameter bahasa, untuk ini kita pakai default dulu atau sesuaikan prompt.
      final result = await _aiService.analyzeImage(imageFile);

      if (mounted) {
        Navigator.pop(context); 
        _showResultSheet(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${tr(ref, 'error')}: $e"), // General error key
            backgroundColor: Colors.redAccent,
          ),
        );
        _resumeCamera();
      }
    }
  }

  Future<void> _launchSearch(String query) async {
    try {
      final Uri url = Uri.https('www.google.com', '/search', {'q': query});
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(ref, 'obj_error_browser'))),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  void _resumeCamera() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
       _cameraController!.startImageStream((image) {
          if (_isDetecting) return;
          _processTrackingFrame(image);
       });
    }
  }

  // --- UI HASIL (Multibahasa) ---
  void _showResultSheet(Map<String, String> data) {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final String name = data['name']!;
    final String description = data['description']!;
    final String query = data['query']!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.60,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ]
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300], 
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
            ),
            const SizedBox(height: 25),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'obj_detected'), // "Terdeteksi"
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        name, 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252535) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ref, 'obj_analysis_title'), // "Analisa Cerdas"
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.blueAccent
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark ? Colors.white70 : Colors.black87
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _launchSearch(query),
                icon: const Icon(Icons.travel_explore, color: Colors.white),
                label: Text(
                  tr(ref, 'obj_btn_search_more'), // "Cari Info Lebih Lanjut"
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  elevation: MaterialStateProperty.all(4),
                  shadowColor: MaterialStateProperty.all(Colors.blueAccent.withOpacity(0.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      _resumeCamera();
    });
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
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
              Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
              InputImageRotation.rotation0deg, 
              color: Colors.greenAccent.withOpacity(0.5),
            ),
            child: Container(),
          ),

          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
                GlassmorphicContainer(
                  width: 160, height: 40,
                  borderRadius: 20, blur: 10, alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(colors: [Colors.black54, Colors.black26]),
                  borderGradient: LinearGradient(colors: [Colors.white24, Colors.white10]),
                  child: Text(
                    tr(ref, 'obj_smart_title'), // "Smart Lens AI"
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _onCapturePressed,
                child: Container(
                  width: 85, height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white24,
                    boxShadow: [
                      BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                    ]
                  ),
                  child: Center(
                    child: Container(
                      width: 65, height: 65,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.search, size: 35, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 150, left: 0, right: 0,
            child: Text(
              tr(ref, 'obj_tap_instruction'), // "Ketuk untuk menganalisa..."
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
            ),
          )
        ],
      ),
    );
  }
}