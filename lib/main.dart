import 'dart:io';
import 'dart:ui' show Locale; // ✅ Import eksplisit hanya Locale
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher_string.dart';

// --- FEATURE IMPORTS ---
import 'ui/theme/app_theme.dart';
import 'ui/widgets/animated_background.dart';
import 'features/object_detection/pages/object_detection_page.dart';
import 'features/ocr/pages/ocr_page.dart';
import 'features/face_recognition/pages/face_recognition_page.dart';
import 'features/qr_scanner/pages/qr_scanner_page.dart';
import 'features/assistant/pages/assistant_page.dart';
import 'features/splash/splash_page.dart';
import 'features/music/pages/music_player_page.dart';
// ✅ ADDED: Import the actual Login Page
import 'features/auth/auth/login_page.dart'; 

import 'core/edge_function_service.dart';
import 'core/localization_service.dart';
import 'core/activity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  timeago.setLocaleMessages('id', timeago.IdMessages());
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('zh', timeago.ZhMessages());
  timeago.setLocaleMessages('ja', timeago.JaMessages());
  timeago.setLocaleMessages('ko', timeago.KoMessages());

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://lsszhahkrgzqnhbwrijo.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxzc3poYWhrcmd6cW5oYndyaWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0Nzk3MzQsImV4cCI6MjA4MDA1NTczNH0.7cfg1ps8Oz7Bo5oYjhpY1uWEDJwA7Ipt7lKPoqr10JA');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  EdgeFunctionService.initialize(supabaseUrl, supabaseAnonKey);

  runApp(const ProviderScope(child: AksaraAIApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()), // Will now use the imported class
    GoRoute(path: '/home', builder: (_, __) => const MainLayout()),
    GoRoute(
        path: '/object-detection',
        builder: (_, __) => const ObjectDetectionPage()),
    GoRoute(path: '/ocr', builder: (_, __) => const OCRPage()),
    GoRoute(
        path: '/face-recognition',
        builder: (_, __) => const FaceRecognitionPage()),
    GoRoute(path: '/qr-scanner', builder: (_, __) => const QRScannerPage()),
    GoRoute(path: '/assistant', builder: (_, __) => const AssistantPage()),
    GoRoute(path: '/music-player', builder: (_, __) => const MusicPlayerPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
    GoRoute(
        path: '/notifications', builder: (_, __) => const NotificationsPage()),
    GoRoute(path: '/language', builder: (_, __) => const LanguagePage()),
    GoRoute(
        path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyPage()),
  ],
);

class AksaraAIApp extends ConsumerWidget {
  const AksaraAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final fontScale = ref.watch(fontSizeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'AksaraAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(fontFamily),
      darkTheme: AppTheme.darkTheme(fontFamily),
      themeMode: themeMode,
      routerConfig: _router,
      locale: ref.watch(localeProvider),

      // ✅ SOLUSI FINAL: Tanpa const, gunakan Locale langsung
      supportedLocales: [
        const Locale('id'),
        const Locale('en'),
        const Locale('ja'),
        const Locale('ko'),
        const Locale('zh'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child!,
        );
      },
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const DashboardPage(),
    const HistoryTab(),
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(isDark: isDark, child: _pages[_currentIndex]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 70,
          borderRadius: 35,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05)
                    ]
                  : [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.3)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderGradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.1)
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.dashboard_rounded, 0, tr(ref, 'home')),
              _navItem(Icons.history_rounded, 1, tr(ref, 'history')),
              _navItem(Icons.person_rounded, 2, tr(ref, 'profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label) => GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _currentIndex == index
                  ? (ref.watch(themeProvider) == ThemeMode.dark
                      ? Colors.cyanAccent
                      : Colors.deepPurple)
                  : (ref.watch(themeProvider) == ThemeMode.dark
                      ? Colors.white70
                      : Colors.grey),
              size: 28,
            ).animate(target: _currentIndex == index ? 1 : 0).scaleXY(end: 1.2),
            if (_currentIndex == index)
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ref.watch(themeProvider) == ThemeMode.dark
                        ? Colors.white
                        : Colors.deepPurple),
              ),
          ],
        ),
      );
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = Supabase.instance.client.auth.currentUser;
    // FIX: Ambil dari metadata agar nama tersimpan
    final String userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'Guest';
    final String? avatarUrl =
        user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
    final String greeting = tr(ref, 'hello');

    void logToolUsage(String route, String titleKey, String descKey,
        IconData icon, Color color) {
      ref
          .read(activityProvider.notifier)
          .addActivity(titleKey, descKey, icon, color);
      context.push(route);
    }

    return SafeArea(
        bottom: false,
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                isDark ? Colors.cyanAccent : Colors.blueAccent,
                            width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4))
                        ]),
                    child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black54))
                            : null)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(greeting,
                          style: GoogleFonts.exo2(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              fontWeight: FontWeight.w500)),
                      Text(userName,
                          style: GoogleFonts.merriweather(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                    ])),
                IconButton(
                    icon: Icon(
                        isDark
                            ? Icons.wb_sunny_rounded
                            : Icons.nights_stay_rounded,
                        color: isDark ? Colors.orangeAccent : Colors.indigo),
                    onPressed: () =>
                        ref.read(themeProvider.notifier).toggleTheme()),
              ]),
              const SizedBox(height: 30),
              _buildAIChatHero(context, ref, isDark),
              const SizedBox(height: 32),
              Text(tr(ref, 'explore').toUpperCase(),
                  style: GoogleFonts.exo2(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : Colors.grey[600])),
              const SizedBox(height: 16),
              Column(children: [
                _buildWideCard(context,
                    title: tr(ref, 'face_id'),
                    subtitle: tr(ref, 'log_face_desc'),
                    icon: Icons.face_retouching_natural_rounded,
                    colors: [const Color(0xFFFFCA28), const Color(0xFFFFA726)],
                    shadowColor: Colors.orange,
                    onTap: () => logToolUsage(
                        '/face-recognition',
                        'log_face_title',
                        'log_face_desc',
                        Icons.face,
                        Colors.orange)),
                const SizedBox(height: 16),
                _buildWideCard(context,
                    title: tr(ref, 'ocr_magic'),
                    subtitle: tr(ref, 'log_ocr_desc'),
                    icon: Icons.document_scanner_rounded,
                    colors: [const Color(0xFF26A69A), const Color(0xFF00897B)],
                    shadowColor: Colors.teal,
                    onTap: () => logToolUsage('/ocr', 'log_ocr_title',
                        'log_ocr_desc', Icons.text_fields, Colors.green)),
                const SizedBox(height: 16),
                _buildWideCard(context,
                    title: tr(ref, 'music_lyrics'),
                    subtitle: tr(ref, 'log_music_desc'),
                    icon: Icons.library_music_rounded,
                    colors: [const Color(0xFF7E57C2), const Color(0xFF5C6BC0)],
                    shadowColor: Colors.indigo,
                    onTap: () => logToolUsage(
                        '/music-player',
                        'log_music_title',
                        'log_music_desc',
                        Icons.music_note,
                        Colors.indigo)),
                const SizedBox(height: 16),
                _buildWideCard(context,
                    title: tr(ref, 'object_detect'),
                    subtitle: tr(ref, 'log_obj_desc'),
                    icon: Icons.view_in_ar_rounded,
                    colors: [const Color(0xFFEC407A), const Color(0xFFAB47BC)],
                    shadowColor: Colors.pink,
                    onTap: () => logToolUsage(
                        '/object-detection',
                        'log_obj_title',
                        'log_obj_desc',
                        Icons.view_in_ar,
                        Colors.pink)),
                const SizedBox(height: 16),
                _buildWideCard(context,
                    title: tr(ref, 'qr_scanner'),
                    subtitle: tr(ref, 'log_qr_desc'),
                    icon: Icons.qr_code_scanner_rounded,
                    colors: [const Color(0xFF42A5F5), const Color(0xFF29B6F6)],
                    shadowColor: Colors.blue,
                    onTap: () => logToolUsage('/qr-scanner', 'log_qr_title',
                        'log_qr_desc', Icons.qr_code, Colors.blue)),
              ]),
            ])));
  }

  Widget _buildAIChatHero(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/assistant'),
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)]),
              boxShadow: [
                BoxShadow(
                    color:
                        isDark ? Colors.black45 : Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.white, width: 1)),
          child: Stack(children: [
            Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.psychology,
                    size: 150,
                    color: (isDark ? Colors.white : Colors.deepPurple)
                        .withOpacity(0.03))),
            Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.cyanAccent.withOpacity(0.2)
                                    : Colors.deepPurple.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Icon(Icons.auto_awesome,
                                    color: isDark
                                        ? Colors.cyanAccent
                                        : Colors.deepPurple,
                                    size: 20)
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(
                                    begin: 1.0, end: 1.2, duration: 1.seconds)),
                        const SizedBox(width: 10),
                        Text(tr(ref, 'assist_title'),
                            style: GoogleFonts.exo2(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.cyanAccent
                                    : Colors.deepPurple,
                                fontSize: 12))
                      ]),
                      const SizedBox(height: 16),
                      Text(tr(ref, 'assist_intro'),
                          style: GoogleFonts.merriweather(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 20),
                      Container(
                          height: 45,
                          decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.withOpacity(0.2))),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(children: [
                            const SizedBox(width: 16),
                            Expanded(
                                child: Text(tr(ref, 'assist_hint'),
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey[400],
                                        fontSize: 14))),
                            Container(
                                margin: const EdgeInsets.all(4),
                                width: 37,
                                height: 37,
                                decoration: const BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.mic_rounded,
                                    color: Colors.white, size: 20))
                          ])),
                    ]))
          ])),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildWideCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required List<Color> colors,
      required Color shadowColor,
      required void Function() onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ]),
            child: Stack(children: [
              Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1)))),
              Positioned(
                  right: 40,
                  bottom: -40,
                  child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1)))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(title,
                              style: GoogleFonts.exo2(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: GoogleFonts.exo2(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8)))
                        ])),
                    Icon(icon, size: 40, color: Colors.white)
                  ]))
            ]))).animate().fadeIn().slideX(
        begin: 0.1, end: 0, duration: 300.ms);
  }
}

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider).languageCode;
    return SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(tr(ref, 'history'),
              style: GoogleFonts.merriweather(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.brown[900]))),
      Expanded(
          child: activities.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.history_toggle_off,
                          size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(tr(ref, 'no_notif'),
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white60 : Colors.brown[300],
                              fontSize: 16))
                    ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: activities.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final item = activities[index];
                    return GlassmorphicContainer(
                        width: double.infinity,
                        height: 90,
                        borderRadius: 16,
                        blur: 10,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(colors: [
                          (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.05),
                          (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.02)
                        ]),
                        borderGradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05)
                        ]),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.2),
                                      shape: BoxShape.circle),
                                  child: Icon(item.icon,
                                      color: item.color, size: 26)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                    Text(tr(ref, item.titleKey),
                                        style: GoogleFonts.exo2(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text(tr(ref, item.descKey),
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(
                                        timeago.format(item.timestamp,
                                            locale: locale),
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey[500],
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic))
                                  ]))
                            ]))).animate().fadeIn().slideY(begin: 0.2, end: 0);
                  }))
    ]));
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = false;
  final _user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // FIX: Load Profil dari Metadata Supabase
  void _loadProfile() {
    // FIX: Gunakan variabel lokal untuk 'Promotion' agar Dart yakin tidak null
    final user = _user;
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            "Guest";
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  // FIX: Simpan Nama ke Supabase
  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'full_name': _nameController.text.trim()}));
      ref.read(activityProvider.notifier).addActivity(
          'notif_name_title', 'notif_name_desc', Icons.badge, Colors.blue);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(tr(ref, 'notif_name_desc'), Colors.green);
        setState(() {});
      }
    } catch (e) {
      if (mounted) _showSnackBar("Gagal: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FIX: Upload Foto ke Bucket 'avatars' dan update metadata
  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (image == null || _user == null) return;
    setState(() => _isLoading = true);
    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName =
          '${_user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload ke Storage
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Ambil Public URL
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update User Metadata
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: {'avatar_url': imageUrl}));

      ref.read(activityProvider.notifier).addActivity('notif_photo_title',
          'notif_photo_desc', Icons.add_a_photo, Colors.pink);
      setState(() => _avatarUrl = imageUrl);
      if (mounted) _showSnackBar(tr(ref, 'notif_photo_desc'), Colors.green);
    } catch (e) {
      if (mounted) _showSnackBar("Gagal upload: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditNameSheet() {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(25))),
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
                      Text(tr(ref, 'edit_name'),
                          style: GoogleFonts.merriweather(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 20),
                      TextField(
                          controller: _nameController,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                              hintText: tr(ref, 'name_hint'),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.white10 : Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.person_outline))),
                      const SizedBox(height: 25),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(tr(ref, 'cancel')))),
                        const SizedBox(width: 15),
                        Expanded(
                            child: ElevatedButton(
                                onPressed: _updateName,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    backgroundColor: Colors.blue),
                                child: Text(tr(ref, 'save'),
                                    style:
                                        const TextStyle(color: Colors.white))))
                      ])
                    ]))));
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(tr(ref, 'delete_account')),
                content: const Text("Tindakan ini tidak bisa dibatalkan."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr(ref, 'cancel'))),
                  ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)))
                ]));
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return SafeArea(
        child: Stack(children: [
      SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(children: [
            GestureDetector(
                onTap: _updateAvatar,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.purpleAccent, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.purple.withOpacity(0.5),
                                blurRadius: 20)
                          ]),
                      child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                      fontSize: 50, color: Colors.white))
                              : null)),
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20))
                ])),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                  child: Text(_nameController.text,
                      style: GoogleFonts.merriweather(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center)),
              IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: _showEditNameSheet)
            ]),
            Text(_user?.email ?? "",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _menu(context, tr(ref, 'settings'), Icons.settings, isDark,
                () => context.push('/settings')),
            _menu(context, tr(ref, 'about_app'), Icons.info_outline, isDark,
                () => context.push('/about')),
            _menu(context, tr(ref, 'privacy'), Icons.privacy_tip_outlined,
                isDark, () => context.push('/privacy-policy')),
            _menu(context, tr(ref, 'language'), Icons.language, isDark,
                () => context.push('/language')),
            _menu(context, "Beri Masukan", Icons.feedback, isDark, () async {
              final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'admin@aksara.ai',
                  query: 'subject=Feedback Aplikasi');
              try {
                await launchUrlString(emailLaunchUri.toString());
              } catch (e) {
                _showSnackBar("Tidak bisa membuka email.", Colors.red);
              }
            }),
            const SizedBox(height: 30),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(tr(ref, 'logout'),
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))))),
            const SizedBox(height: 15),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: Text(tr(ref, 'delete_account'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1.5),
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))))),
            const SizedBox(height: 100)
          ])),
      if (_isLoading)
        Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()))
    ]));
  }

  Widget _menu(
          BuildContext c, String t, IconData i, bool d, void Function() o) =>
      Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
              color: d ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: d
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 3))
                    ]),
          child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(i, color: Colors.blue)),
              title: Text(t,
                  style: TextStyle(
                      color: d ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: o));
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final currentScale = ref.watch(fontSizeProvider);
    final currentFont = ref.watch(fontFamilyProvider);
    return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[100],
        appBar: AppBar(
            title: Text(tr(ref, 'settings')),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _sectionTitle(tr(ref, 'appearance'), isDark),
          _glassSection(isDark, [
            SwitchListTile(
                title: Text(tr(ref, 'dark_mode'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.dark_mode, color: Colors.purple)),
                value: isDark,
                activeColor: Colors.white,
                activeTrackColor: Colors.blueAccent,
                onChanged: (val) =>
                    ref.read(themeProvider.notifier).toggleTheme()),
            const Divider(),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(ref, 'font_size'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                      Row(children: [
                        const Icon(Icons.text_fields,
                            size: 16, color: Colors.grey),
                        Expanded(
                            child: Slider(
                                value: currentScale,
                                min: 0.8,
                                max: 1.2,
                                divisions: 4,
                                label: "${(currentScale * 100).toInt()}%",
                                activeColor: Colors.blueAccent,
                                onChanged: (val) => ref
                                    .read(fontSizeProvider.notifier)
                                    .state = val)),
                        const Icon(Icons.text_fields,
                            size: 24, color: Colors.grey)
                      ])
                    ])),
            const Divider(),
            ListTile(
                title: Text(tr(ref, 'font_style'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child:
                        const Icon(Icons.font_download, color: Colors.orange)),
                trailing: DropdownButton<String>(
                    value: currentFont,
                    dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                          value: 'modern',
                          child: Text(tr(ref, 'style_modern'),
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black))),
                      DropdownMenuItem(
                          value: 'classic',
                          child: Text(tr(ref, 'style_classic'),
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black))),
                      DropdownMenuItem(
                          value: 'mono',
                          child: Text(tr(ref, 'style_monospaced'),
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black)))
                    ],
                    onChanged: (val) {
                      if (val != null)
                        ref.read(fontFamilyProvider.notifier).state = val;
                    }))
          ])
        ]));
  }

  Widget _sectionTitle(String title, bool isDark) => Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title.toUpperCase(),
          style: GoogleFonts.exo2(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.grey[600],
              letterSpacing: 1.5)));

  Widget _glassSection(bool isDark, List<Widget> children) => Container(
      decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
      child: Column(children: children));
}

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
                title: Text(tr(ref, 'about_app')),
                bottom: TabBar(
                    indicatorColor: Colors.blueAccent,
                    labelColor: isDark ? Colors.white : Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: tr(ref, 'tab_background')),
                      Tab(text: tr(ref, 'tab_features')),
                      Tab(text: tr(ref, 'tab_devs'))
                    ])),
            body: TabBarView(children: [
              SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.auto_awesome,
                        size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text("AKSARA AI",
                        style: GoogleFonts.orbitron(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(tr(ref, 'app_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? Colors.white70 : Colors.black87))
                  ])),
              ListView(padding: const EdgeInsets.all(20), children: [
                _featureTile(
                    Icons.face, tr(ref, 'feat_face'), isDark, Colors.orange),
                _featureTile(Icons.document_scanner, tr(ref, 'feat_ocr'),
                    isDark, Colors.green),
                _featureTile(Icons.view_in_ar, tr(ref, 'feat_obj'), isDark,
                    Colors.purple),
                _featureTile(Icons.qr_code_scanner, tr(ref, 'feat_qr'), isDark,
                    Colors.blue),
                _featureTile(
                    Icons.music_note, tr(ref, 'feat_music'), isDark, Colors.red)
              ]),
              SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _devCard(
                        "Muhammad Ferbyadi", "2303421027", Colors.blue, isDark),
                    _devCard("Ananda Afif Fauzan", "2303421025", Colors.orange,
                        isDark),
                    _devCard("Lintang Dyahayuningsih", "2303421038",
                        Colors.pink, isDark)
                  ]))
            ])));
  }

  Widget _featureTile(IconData icon, String title, bool isDark, Color color) =>
      Card(
          color: isDark ? Colors.white10 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color)),
              title: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black))));

  Widget _devCard(String name, String nim, Color color, bool isDark) =>
      Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Row(children: [
            CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.2),
                child: Text(name[0],
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color))),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              Text(nim, style: const TextStyle(color: Colors.grey))
            ])
          ])).animate().slideX();
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'history'))),
      body: Center(child: Text(tr(ref, 'no_notif'))));
}

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  final List<Map<String, String>> languages = const [
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語 (Jepang)', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어 (Korea)', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文 (Mandarin)', 'flag': '🇨🇳'}
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(tr(ref, 'select_language')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading:
                  Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(
                lang['name']!,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              trailing: current == lang['code']
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              onTap: () {
                // ✅ FIX: Gunakan ui.Locale dengan prefix
                ref.read(localeProvider.notifier).state = Locale(lang['code']!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${lang['name']}"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
            title: Text(tr(ref, 'privacy'),
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme:
                IconThemeData(color: isDark ? Colors.white : Colors.black)),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(ref, 'privacy'),
                  style: GoogleFonts.merriweather(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("1. Data",
                            style: GoogleFonts.exo2(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent)),
                        const SizedBox(height: 8),
                        Text("We collect data securely.",
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: isDark
                                    ? Colors.grey[100]
                                    : Colors.grey[800]))
                      ]))
            ])));
  }
}