# 🚀 AksaraAI Assist

**AksaraAI Assist** adalah aplikasi *mobile* berbasis Flutter yang mendemonstrasikan integrasi layanan *backend* Supabase dengan fitur *Artificial Intelligence* (AI) dan *Machine Learning* (ML) real-time. Aplikasi ini menampilkan 5 fitur AI/ML canggih, mulai dari deteksi objek hingga asisten percakapan cerdas.

## ✨ Fitur Utama (AI Real-Time)

| No. | Fitur AI | Deskripsi & Teknologi Kunci |
| :--- | :--- | :--- |
| **1** | **Realtime Object Detection** | Deteksi objek real-time menggunakan model **TFLite**. Hasil deteksi di-*stream* menggunakan **Supabase Realtime**. |
| **2** | **OCR Realtime with Enhancement** | Pengenalan teks (OCR) menggunakan **MLKit**. Teks ditingkatkan (*enhanced*) kualitasnya melalui **Supabase Edge Function** sebelum dipublikasikan via Realtime. |
| **3** | **Face Recognition & Matching** | Ekstraksi *embedding* wajah (FaceNet/ArcFace) dan pencocokan (*matching*) menggunakan **pgvector (Cosine Similarity)**. Proses *matching* dilakukan di **Edge Function**. |
| **4** | **AI-enhanced QR/Barcode Scanner** | Scanning cepat dengan `mobile_scanner`. Dilengkapi fitur *Recovery AI* melalui **Edge Function** untuk memulihkan QR/Barcode yang rusak. |
| **5** | **Conversational Assistant** | Asisten berbasis chat dengan alur: **Speech-to-Text** (STT) on-device, diproses oleh **LLM via Edge Function**, kemudian direspons dengan **Text-to-Speech** (TTS), termasuk eksekusi perintah otomatis. |

## 🛠️ Tumpukan Teknologi

* **Frontend:** Flutter 3.22+
* **Backend:** Supabase (Auth, Storage, Realtime, Postgres, Edge Functions)
* **State Management:** Riverpod
* **AI/ML Tools:** TFLite, ML Kit Text Recognition, `pgvector`
* **Integrasi:** `mobile_scanner`, `flutter_tts`, `speech_to_text`

## 📁 Struktur Direktori Kunci
