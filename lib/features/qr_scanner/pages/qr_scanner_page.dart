import 'package:flutter/material.dart'; // WAJIB ADA
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/qr_scanner_service.dart';
import '../../../core/localization_service.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});
  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isRecovering = false;
  String? _lastResult;
  bool _isDialogShowing = false;

  void _onScanSuccess(Code? result) {
    if (_isDialogShowing) return;
    if (result != null && result.text != null) {
      if (result.text == _lastResult) return;
      setState(() => _lastResult = result.text);
      _handleSmartResult(result.text!, result.format?.name ?? "QR Code");
    }
  }

  void _handleSmartResult(String code, String type) {
    setState(() => _isDialogShowing = true);

    bool isQRIS =
        code.contains("000201") || code.toLowerCase().contains("qris");
    bool isInstagram = code.contains("instagram.com") ||
        code.contains("instagr.am") ||
        code.startsWith("instagram://");
    bool isWhatsapp = code.contains("wa.me") || code.startsWith("whatsapp:");
    bool isYoutube = code.contains("youtube.com") || code.contains("youtu.be");
    bool isUrl = (code.startsWith("http") || code.startsWith("www.")) &&
        !isInstagram &&
        !isWhatsapp &&
        !isYoutube;

    showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => _buildSmartSheet(
                code, type, isQRIS, isUrl, isWhatsapp, isInstagram, isYoutube))
        .then((_) {
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
          _lastResult = null;
        });
      }
    });
  }

  Widget _buildSmartSheet(String code, String type, bool isQRIS, bool isUrl,
      bool isWA, bool isIG, bool isYT) {
    Color themeColor = Colors.purple;
    IconData themeIcon = Icons.text_fields;

    String title = tr(ref, 'text_title');
    String btnLabel = tr(ref, 'copy_text');
    IconData btnIcon = Icons.copy;

    if (isQRIS) {
      themeColor = Colors.orange;
      themeIcon = Icons.qr_code_scanner;
      title = tr(ref, 'qris_title');
    } else if (isIG) {
      themeColor = const Color(0xFFE1306C);
      themeIcon = Icons.camera_alt;
      title = 'Instagram';
      btnLabel = 'Buka Profil';
      btnIcon = Icons.open_in_new;
    } else if (isWA) {
      themeColor = Colors.green;
      themeIcon = Icons.chat;
      title = 'WhatsApp';
      btnLabel = 'Chat Sekarang';
      btnIcon = Icons.send;
    } else if (isYT) {
      themeColor = Colors.red;
      themeIcon = Icons.play_circle_fill;
      title = 'YouTube';
      btnLabel = 'Tonton Video';
      btnIcon = Icons.play_arrow;
    } else if (isUrl) {
      themeColor = Colors.blue;
      themeIcon = Icons.public;
      title = tr(ref, 'link_title');
      btnLabel = tr(ref, 'qr_open');
      btnIcon = Icons.open_in_browser;
    }

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(themeIcon, color: themeColor, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.exo2(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                        isQRIS
                            ? tr(ref, 'pay_via')
                            : "${tr(ref, 'scan_result')} $type",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: Text(code,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.courierPrime(
                      fontSize: 13, color: Colors.black87))),
          const SizedBox(height: 25),
          if (isQRIS) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () => _showPaymentAppsDialog(context, code),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(tr(ref, 'choose_app'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ),
          ] else if (isUrl || isWA || isIG || isYT) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () => _confirmAndLaunchUrl(context, code, title),
                  icon: Icon(btnIcon, color: Colors.white),
                  label: Text(btnLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(context);
                    _showSnackBar(tr(ref, 'text_copied'), Colors.green);
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: Text(tr(ref, 'copy_text'),
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ),
          ],
          const SizedBox(height: 15),
          if (isQRIS || isUrl || isWA || isIG || isYT)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(context);
                    _showSnackBar(tr(ref, 'text_copied'), Colors.black);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(tr(ref, 'qr_copy')),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            )
        ],
      ),
    );
  }

  void _showPaymentAppsDialog(BuildContext context, String code) {
    Navigator.pop(context);
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25))),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(ref, 'pay_via'),
                      style: GoogleFonts.exo2(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(tr(ref, 'auto_copy_msg'),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.blue))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _paymentOption("GoPay", "gojek://gopay/pay", code,
                          Colors.green, Icons.motorcycle),
                      _paymentOption("OVO", "ovo://scan", code, Colors.purple,
                          Icons.circle_outlined),
                      _paymentOption("Dana", "dana://pay", code, Colors.blue,
                          Icons.account_balance_wallet),
                      _paymentOption("Shopee", "shopeeid://", code,
                          Colors.orange, Icons.shopping_bag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr(ref, 'cancel'),
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                ],
              ),
            ));
  }

  Widget _paymentOption(String name, String scheme, String codeToCopy,
      Color color, IconData icon) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: codeToCopy));
        try {
          final uri = Uri.parse(scheme);
          bool launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            if (mounted) {
              Navigator.pop(context);
              _showSnackBar(tr(ref, 'link_opened'), Colors.black87);
            }
          } else {
            throw 'Gagal';
          }
        } catch (e) {
          if (mounted) _showErrorDialog(name);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  void _showErrorDialog(String appName) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(tr(ref, 'app_not_found')),
              content: Text("$appName tidak ditemukan."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"))
              ],
            ));
  }

  Future<void> _confirmAndLaunchUrl(
      BuildContext context, String url, String typeName) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(tr(ref, 'link_opened')),
              content: Text(url),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr(ref, 'cancel'))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Open"))
              ],
            ));

    if (confirm == true) {
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnackBar("Error", Colors.red);
      }
    }
  }

  Future<void> _pickImageAndRecover() async {
    setState(() => _isRecovering = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final result = await ref
            .read(qRScannerServiceProvider.notifier)
            .recoverQRCode(image);
        if (result.containsKey('decoded_text')) {
          _handleSmartResult(result['decoded_text'], result['method']);
        } else {
          _showSnackBar(result['error'] ?? tr(ref, 'qr_fail'), Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isRecovering = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))
          ]));
  Widget _corner(int rotate) => RotatedBox(
      quarterTurns: rotate,
      child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.white, width: 4),
                  left: BorderSide(color: Colors.white, width: 4)))));

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    return Scaffold(
      body: Stack(children: [
        ReaderWidget(
            onScan: _onScanSuccess,
            resolution: ResolutionPreset.high,
            showFlashlight: false,
            showGallery: false,
            showToggleCamera: false,
            scanDelay: const Duration(milliseconds: 500),
            cropPercent: 0.7),
        SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context))),
                    GlassmorphicContainer(
                        width: 160,
                        height: 40,
                        borderRadius: 20,
                        blur: 10,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05)
                        ]),
                        borderGradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.1)
                        ]),
                        child: Text(tr(ref, 'qr_title'),
                            style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2))),
                    const SizedBox(width: 40)
                  ])),
          const Spacer(),
          Center(
              child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.7),
                          width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ]),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [_corner(0), _corner(1)]),
                        const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.add, color: Colors.white54)),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [_corner(3), _corner(2)])
                      ]))),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionBtn(Icons.flash_on, tr(ref, 'qr_flash'), () {}),
                    GestureDetector(
                        onTap: _isRecovering ? null : _pickImageAndRecover,
                        child: Column(children: [
                          Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                  color: Colors.purpleAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.purple.withOpacity(0.5),
                                        blurRadius: 15)
                                  ]),
                              child: _isRecovering
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.image_search,
                                      color: Colors.white, size: 28)),
                          const SizedBox(height: 8),
                          Text(tr(ref, 'qr_recovery'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12))
                        ])),
                    _actionBtn(Icons.history, tr(ref, 'history'), () {})
                  ]))
        ]))
      ]),
    );
  }
}
