# AksaraAI Assist

Aplikasi Flutter kompleks dengan **5 fitur AI realtime** yang didukung oleh Supabase.

## 🎯 Fitur

1. **Realtime Object Detection (TFLite)**
   - Deteksi objek realtime menggunakan model TFLite
   - Streaming hasil deteksi ke Supabase Realtime

2. **OCR Realtime (MLKit + Supabase Edge Function)**
   - Pengenalan teks menggunakan MLKit
   - Enhancement AI melalui Edge Function
   - Hasil dipublikasikan via Realtime

3. **Face Recognition (Embedding + Matching)**
   - Ekstraksi embedding wajah menggunakan FaceNet/ArcFace
   - Matching menggunakan pgvector cosine similarity
   - Edge Function untuk proses matching

4. **AI-enhanced QR/Barcode Scanner**
   - Scanning menggunakan `mobile_scanner`
   - Recovery AI untuk QR code yang rusak/tidak jelas

5. **Conversational Assistant (STT → LLM → TTS + Commands)**
   - Speech-to-Text on-device
   - Integrasi LLM via Edge Function
   - Text-to-Speech response
   - Eksekusi perintah otomatis

## 🛠️ Tech Stack

- **Flutter** 3.22+
- **Supabase** (Auth, Storage, Realtime, Postgres, Edge Functions)
- **TFLite** (tflite_flutter)
- **ML Kit** Text Recognition
- **mobile_scanner**
- **Riverpod** untuk state management
- **flutter_tts**
- **speech_to_text**

## 📁 Struktur Proyek

```
/lib
  /core
    supabase_client.dart
    edge_function_service.dart
  /features
    /object_detection
      /pages
      /services
      /widgets
    /ocr
      /pages
      /services
    /face_recognition
      /pages
      /services
    /qr_scanner
      /pages
      /services
    /assistant
      /pages
      /services
/assets/models
  object_detection.tflite
  face_recognition.tflite
/supabase/edge_functions
  ai_chat/
  ocr_enhance/
  face_match/
  qr_recovery/
/test
```

## 🚀 Setup & Instalasi

### 1. Prerequisites

- Flutter SDK 3.22 atau lebih baru
- Dart SDK 3.0 atau lebih baru
- Supabase account dan project
- Android Studio / Xcode untuk development

### 2. Clone & Install Dependencies

```bash
# Install dependencies
flutter pub get

# Generate Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Konfigurasi Supabase

1. Buat project di [Supabase](https://supabase.com)
2. Dapatkan URL dan Anon Key dari project settings
3. Set environment variables atau hardcode di `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 4. Setup Supabase Storage Buckets

Buat bucket berikut di Supabase Storage:

- `ocr_images` - untuk menyimpan gambar OCR
- `qr_images` - untuk menyimpan gambar QR recovery

### 5. Setup Database (untuk Face Recognition)

Jalankan SQL berikut di Supabase SQL Editor:

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create face_embeddings table
CREATE TABLE face_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_name TEXT NOT NULL,
  embedding vector(128),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for similarity search
CREATE INDEX ON face_embeddings USING ivfflat (embedding vector_cosine_ops);

-- Create function for face matching
CREATE OR REPLACE FUNCTION match_face_embedding(
  query_embedding vector(128),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  person_name text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    face_embeddings.id,
    face_embeddings.person_name,
    1 - (face_embeddings.embedding <=> query_embedding) as similarity
  FROM face_embeddings
  WHERE 1 - (face_embeddings.embedding <=> query_embedding) > match_threshold
  ORDER BY face_embeddings.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

### 6. Deploy Edge Functions

```bash
# Install Supabase CLI
npm install -g supabase

# Login ke Supabase
supabase login

# Link ke project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy semua edge functions
supabase functions deploy ai_chat
supabase functions deploy ocr_enhance
supabase functions deploy face_match
supabase functions deploy qr_recovery
```

### 7. Menambahkan Model TFLite

1. Download atau train model TFLite untuk:
   - Object Detection: `assets/models/object_detection.tflite`
   - Face Recognition: `assets/models/face_recognition.tflite`

2. Place model files di folder `assets/models/`

3. Update `pubspec.yaml` untuk include assets (sudah ada)

### 8. Menjalankan Aplikasi

```bash
# Run di device/emulator
flutter run

# Build untuk production
flutter build apk  # Android
flutter build ios  # iOS
```

## 📝 Environment Variables

Untuk production, gunakan environment variables:

```bash
# Android (android/app/build.gradle)
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key

# iOS (ios/Runner/Info.plist atau via Xcode)
```

Atau gunakan `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run dengan coverage
flutter test --coverage
```

## 📊 Arsitektur Data

### Realtime Channels

- `object_detect` - Streaming hasil object detection
- `ocr_results` - Hasil OCR processing
- `ai_chat` - Chat messages dan responses
- `qr_recovery` - QR recovery results

### Storage Buckets

- `ocr_images` - Gambar untuk OCR processing
- `qr_images` - Gambar untuk QR recovery

### Database Tables

- `face_embeddings` - Face embeddings dengan pgvector

## 🔌 Edge Functions API

### 1. `ai_chat`

**Request:**
```json
{
  "message": "Halo, buka QR scanner",
  "user_id": "user-uuid"
}
```

**Response:**
```json
{
  "text": "Baik, saya akan membuka QR scanner untuk Anda.",
  "action": {
    "type": "scan_qr"
  }
}
```

### 2. `ocr_enhance`

**Request:**
```json
{
  "image_url": "https://...",
  "image_id": "image-id"
}
```

**Response:**
```json
{
  "enhanced_text": "Teks hasil OCR yang ditingkatkan",
  "confidence": 0.92,
  "language": "id"
}
```

### 3. `face_match`

**Request:**
```json
{
  "embedding": [0.1, 0.2, ...] // 128 dimensions
}
```

**Response:**
```json
{
  "matched": true,
  "person_name": "John Doe",
  "similarity": 0.95,
  "person_id": "uuid"
}
```

### 4. `qr_recovery`

**Request:**
```json
{
  "image_url": "https://..."
}
```

**Response:**
```json
{
  "decoded_text": "https://example.com",
  "confidence": 0.85,
  "format": "QR_CODE"
}
```

## 🎨 UI/UX

Aplikasi menggunakan Material Design 3 dengan:
- Navigation menggunakan GoRouter
- State management dengan Riverpod
- Modern UI dengan cards dan animations
- Realtime updates via Supabase channels

## 📌 TODO / Sprint Checklist

### Sprint 1: Setup Supabase & Flutter ✅
- [x] Setup Flutter project
- [x] Konfigurasi Supabase client
- [x] Setup routing dan navigation
- [x] Basic UI structure

### Sprint 2: Object Detection ✅
- [x] Integrasi TFLite
- [x] Camera preview dengan overlay
- [x] Realtime detection streaming
- [x] Supabase Realtime integration

### Sprint 3: OCR ✅
- [x] MLKit integration
- [x] Image upload ke Supabase Storage
- [x] Edge Function untuk enhancement
- [x] Realtime result publishing

### Sprint 4: Face Recognition ✅
- [x] Face embedding extraction
- [x] Edge Function untuk matching
- [x] pgvector integration (database setup)
- [x] Similarity calculation

### Sprint 5: Assistant AI ✅
- [x] STT integration
- [x] Edge Function untuk LLM
- [x] TTS integration
- [x] Command execution

### Sprint 6: Testing & Final Integration
- [x] Unit tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Error handling improvements
- [ ] Production deployment

## 🔧 Troubleshooting

### Model TFLite tidak ditemukan
- Pastikan file model ada di `assets/models/`
- Run `flutter clean` dan `flutter pub get`
- Check `pubspec.yaml` assets configuration

### Supabase connection error
- Verify URL dan Anon Key
- Check network connectivity
- Verify Supabase project status

### Edge Functions tidak berjalan
- Pastikan sudah di-deploy dengan benar
- Check Supabase dashboard untuk logs
- Verify function permissions

## 📄 License

MIT License

## 👥 Contributors

Dibangun dengan ❤️ menggunakan Flutter dan Supabase

---

**Catatan:** Aplikasi ini adalah proof-of-concept. Untuk production, pastikan untuk:
- Mengganti mock responses dengan actual AI/ML APIs
- Implement proper error handling
- Add authentication & authorization
- Optimize performance
- Add comprehensive testing


