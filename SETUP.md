# Setup Guide - AksaraAI Assist

## Quick Start

### 1. Install Dependencies

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Configure Supabase

Edit `lib/main.dart` and replace:
- `YOUR_SUPABASE_URL` with your Supabase project URL
- `YOUR_SUPABASE_ANON_KEY` with your Supabase anon key

### 3. Setup Supabase Resources

#### Storage Buckets
Create these buckets in Supabase Dashboard:
- `ocr_images` (public)
- `qr_images` (public)

#### Database Migration
Run the SQL from `supabase/migrations/001_face_embeddings.sql` in Supabase SQL Editor.

#### Edge Functions
Deploy all edge functions:

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy functions
supabase functions deploy ai_chat
supabase functions deploy ocr_enhance
supabase functions deploy face_match
supabase functions deploy qr_recovery
```

### 4. Add TFLite Models

Place your models in `assets/models/`:
- `object_detection.tflite`
- `face_recognition.tflite`

**Note:** For POC, the app will work in mock mode without models.

### 5. Run the App

```bash
flutter run
```

## Platform-Specific Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access required for object detection and OCR</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access required for voice assistant</string>
```

## Troubleshooting

### Models Not Found
- App will use mock mode automatically
- Add models to `assets/models/` for real detection

### Supabase Connection Issues
- Verify URL and key in `main.dart`
- Check Supabase project is active
- Verify network connectivity

### Edge Functions Not Working
- Check function logs in Supabase Dashboard
- Verify function deployment status
- Check function permissions


