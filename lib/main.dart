import 'dart:io';
import 'dart:ui' show Locale;
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
import 'features/auth/auth/login_page.dart';
import 'features/history/pages/history_pages.dart';
import 'features/about/pages/about_page.dart';
import 'features/legal/pages/privacy_policy_page.dart';

// --- CORE IMPORTS ---
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
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    GoRoute(path: '/home', builder: (_, __) => const MainLayout()),
    GoRoute(path: '/object-detection', builder: (_, __) => ObjectDetectionPage()),
    GoRoute(path: '/ocr', builder: (_, __) => OCRPage()),
    GoRoute(path: '/face-recognition', builder: (_, __) => FaceRecognitionPage()),
    GoRoute(path: '/qr-scanner', builder: (_, __) => QRScannerPage()),
    GoRoute(path: '/assistant', builder: (_, __) => const AssistantPage()),
    GoRoute(path: '/music-player', builder: (_, __) => const MusicPlayerPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
    GoRoute(path: '/language', builder: (_, __) => const LanguagePage()),
    GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
    GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyPage()),
  ],
);

class AksaraAIApp extends ConsumerWidget {
  const AksaraAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers from localization_service.dart
    final fontScale = ref.watch(fontSizeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'AksaraAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(fontFamily),
      darkTheme: AppTheme.darkTheme(fontFamily),
      themeMode: themeMode,
      routerConfig: _router,
      locale: locale,
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
        Locale('zh'),
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
    const HistoryPage(), 
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
                    ]),
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
                  color: _currentIndex == index
                      ? (ref.watch(themeProvider) == ThemeMode.dark
                          ? Colors.cyanAccent
                          : Colors.deepPurple)
                      : (ref.watch(themeProvider) == ThemeMode.dark
                          ? Colors.white70
                          : Colors.grey),
                  size: 28)
              .animate(target: _currentIndex == index ? 1 : 0)
              .scaleXY(end: 1.2),
          if (_currentIndex == index)
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ref.watch(themeProvider) == ThemeMode.dark
                        ? Colors.white
                        : Colors.deepPurple)),
        ]),
      );
}

// --- DASHBOARD PAGE ---
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = Supabase.instance.client.auth.currentUser;

    final String userName = user?.userMetadata?['display_name'] ??
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'Guest';
    final String? avatarUrl = user?.userMetadata?['display_avatar'] ??
        user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];
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
                            width: 2)),
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
                              color:
                                  isDark ? Colors.white70 : Colors.grey[700])),
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
              GestureDetector(
                  onTap: () => context.push('/assistant'),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1A1A2E),
                                      const Color(0xFF16213E)
                                    ]
                                  : [
                                      const Color(0xFFE3F2FD),
                                      const Color(0xFFF3E5F5)
                                    ]),
                          boxShadow: [
                            BoxShadow(
                                color: isDark
                                    ? Colors.black45
                                    : Colors.grey.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8))
                          ],
                          border: Border.all(
                              color: isDark ? Colors.white10 : Colors.white)),
                      child: Stack(children: [
                        Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(Icons.psychology,
                                size: 150,
                                color:
                                    (isDark ? Colors.white : Colors.deepPurple)
                                        .withOpacity(0.03))),
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.auto_awesome,
                                        color: isDark
                                            ? Colors.cyanAccent
                                            : Colors.deepPurple,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Text(tr(ref, 'assist_title'),
                                        style: GoogleFonts.exo2(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.cyanAccent
                                                : Colors.deepPurple))
                                  ]),
                                  const SizedBox(height: 16),
                                  Text(tr(ref, 'assist_intro'),
                                      style: GoogleFonts.merriweather(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87)),
                                  const SizedBox(height: 20),
                                  Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black26
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(children: [
                                        Expanded(
                                            child: Text(tr(ref, 'assist_hint'),
                                                style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey[400]))),
                                        const Icon(Icons.mic_rounded,
                                            color: Colors.deepPurple)
                                      ]))
                                ]))
                      ]))).animate().fadeIn().slideY(),
              const SizedBox(height: 32),
              Text(tr(ref, 'explore').toUpperCase(),
                  style: GoogleFonts.exo2(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : Colors.grey[600])),
              const SizedBox(height: 16),
              Column(children: [
                _featureCard(
                    context,
                    tr(ref, 'feat_face'),
                    tr(ref, 'desc_face'),
                    Icons.face_retouching_natural_rounded,
                    [Colors.orange, Colors.amber],
                    () => logToolUsage('/face-recognition', 'log_face_title',
                        'log_face_desc', Icons.face, Colors.orange)),
                _featureCard(
                    context,
                    tr(ref, 'feat_ocr'),
                    tr(ref, 'desc_ocr'),
                    Icons.document_scanner_rounded,
                    [Colors.teal, Colors.green],
                    () => logToolUsage('/ocr', 'log_ocr_title', 'log_ocr_desc',
                        Icons.text_fields, Colors.green)),
                _featureCard(
                    context,
                    tr(ref, 'feat_music'),
                    tr(ref, 'desc_music'),
                    Icons.library_music_rounded,
                    [Colors.purple, Colors.indigo],
                    () => logToolUsage('/music-player', 'log_music_title',
                        'log_music_desc', Icons.music_note, Colors.indigo)),
                _featureCard(
                    context,
                    tr(ref, 'feat_obj'),
                    tr(ref, 'desc_obj'),
                    Icons.view_in_ar_rounded,
                    [Colors.pink, Colors.purpleAccent],
                    () => logToolUsage('/object-detection', 'log_obj_title',
                        'log_obj_desc', Icons.view_in_ar, Colors.pink)),
                _featureCard(
                    context,
                    tr(ref, 'feat_qr'),
                    tr(ref, 'desc_qr'),
                    Icons.qr_code_scanner_rounded,
                    [Colors.blue, Colors.lightBlue],
                    () => logToolUsage('/qr-scanner', 'log_qr_title',
                        'log_qr_desc', Icons.qr_code, Colors.blue)),
              ]),
            ])));
  }

  Widget _featureCard(BuildContext context, String title, String subtitle,
      IconData icon, List<Color> colors, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: colors),
                boxShadow: [
                  BoxShadow(
                      color: colors[0].withOpacity(0.4),
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
                                  color: Colors.white.withOpacity(0.8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                        ])),
                    Icon(icon, size: 40, color: Colors.white)
                  ]))
            ]))).animate().fadeIn().slideX();
  }
}

// --- PROFILE PAGE ---
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

  void _loadProfile() {
    final user = _user; 
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['display_name'] ??
            user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            "Guest";
        _avatarUrl = user.userMetadata?['display_avatar'] ??
            user.userMetadata?['avatar_url'];
      });
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {
        'display_name': _nameController.text.trim(),
        'full_name': _nameController.text.trim()
      }));
      ref.read(activityProvider.notifier).addActivity(
          'notif_name_title', 'notif_name_desc', Icons.badge, Colors.blue);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(ref, 'notif_name_desc')),
            backgroundColor: Colors.green));
        setState(() {});
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      await Supabase.instance.client.auth.updateUser(UserAttributes(
          data: {'display_avatar': imageUrl, 'avatar_url': imageUrl}));
      ref.read(activityProvider.notifier).addActivity('notif_photo_title',
          'notif_photo_desc', Icons.add_a_photo, Colors.pink);
      setState(() => _avatarUrl = imageUrl);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(ref, 'notif_photo_desc')),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal upload: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(children: [
              GestureDetector(
                  onTap: _updateAvatar,
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.purpleAccent, width: 3),
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
                        overflow: TextOverflow.ellipsis)),
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
              _menu(context, tr(ref, 'feedback'), Icons.feedback, isDark,
                  () async {
                final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'febryadi845@gmail.com',
                    query: 'subject=Feedback Aplikasi Aksara AI');
                try {
                  await launchUrlString(emailLaunchUri.toString());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Tidak bisa membuka email app."),
                      backgroundColor: Colors.red));
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
                      icon: const Icon(Icons.logout),
                      label: Text(tr(ref, 'logout')),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16)))),
              const SizedBox(height: 15),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: Text(tr(ref, 'delete_account')),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16)))),
              const SizedBox(height: 100),
            ])));
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
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(tr(ref, 'edit_name'),
                      style: TextStyle(
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
                              isDark ? Colors.white10 : Colors.grey[100])),
                  const SizedBox(height: 25),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(tr(ref, 'cancel')))),
                    const SizedBox(width: 15),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: _updateName,
                            child: Text(tr(ref, 'save'))))
                  ])
                ]))));
  }

  Future<void> _deleteAccount() async {
    // Placeholder
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
                          color: Colors.grey.withOpacity(0.1), blurRadius: 5)
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

// --- SETTINGS PAGE ---
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    final List<String> fontOptions = [
      'Plus Jakarta Sans',
      'Roboto', 
      'Lato',
      'Poppins',
      'Montserrat',
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(tr(ref, 'settings'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr(ref, 'appearance'), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(tr(ref, 'dark_mode'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.dark_mode_rounded, color: Colors.purple),
                  ),
                  value: isDark,
                  onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.2)),
                
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.text_format_rounded, color: Colors.blue),
                  ),
                  title: Text(tr(ref, 'font_style'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text(ref.watch(fontFamilyProvider), style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: fontOptions.contains(ref.watch(fontFamilyProvider)) ? ref.watch(fontFamilyProvider) : fontOptions.first,
                      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                      items: fontOptions.map((String font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(font, style: GoogleFonts.getFont(font, color: isDark ? Colors.white : Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(fontFamilyProvider.notifier).state = newValue;
                        }
                      },
                    ),
                  ),
                ),
                
                Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.2)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.format_size_rounded, color: Colors.green),
                  ),
                  title: Text(tr(ref, 'font_size'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  trailing: SizedBox(
                    width: 120,
                    child: Slider(
                      value: ref.watch(fontSizeProvider),
                      min: 0.8,
                      max: 1.2,
                      divisions: 4,
                      activeColor: Colors.green,
                      onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(tr(ref, 'system_data'), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
                  title: Text(tr(ref, 'clear_cache'), style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text(tr(ref, 'cache_desc'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(ref, 'cache_cleared'))));
                  },
                ),
                Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.2)),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.teal),
                  title: Text(tr(ref, 'app_version'), style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black)),
                  trailing: Text("v1.2.0 (Beta)", style: GoogleFonts.sourceCodePro(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NOTIFICATIONS PAGE ---
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'history'))),
      body: Center(child: Text(tr(ref, 'no_notif'))));
}

// --- LANGUAGE PAGE ---
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
          title: Text(tr(ref, 'select_language'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme:
              IconThemeData(color: isDark ? Colors.white : Colors.black)),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = current == lang['code'];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.blue) : null),
            child: ListTile(
              leading:
                  Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(lang['name']!,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).state = Locale(lang['code']!);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Bahasa diubah ke ${lang['name']}"),
                    backgroundColor: Colors.green));
              },
            ),
          );
        },
      ),
    );
  }
}