import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aksara AI")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, size: 50, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  Text("Aksara AI Assist", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Versi 1.0.0", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- LATAR BELAKANG ---
            _buildSectionHeader("Latar Belakang"),
            Text(
              "Aksara AI lahir dari sebuah ide sederhana: bagaimana jika setiap orang memiliki asisten pribadi yang selalu siap membantu kapan saja?\n\n"
              "Di tengah derasnya arus informasi, kami percaya bahwa teknologi Artificial Intelligence harusnya memudahkan, bukan membingungkan. Aksara AI dibangun untuk menjadi teman cerdasmu dalam belajar, berkarya, dan menemukan jawaban.\n\n"
              "Menggabungkan kecanggihan Large Language Model dengan antarmuka yang ramah, Aksara AI hadir untuk meningkatkan produktivitas dan kreativitasmu sehari-hari.",
              textAlign: TextAlign.justify,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: Colors.grey[800]),
            ),
            const SizedBox(height: 32),

            // --- 5 FITUR UTAMA ---
            _buildSectionHeader("Fitur Utama"),
            _buildFeatureItem("AI Chatbot Cerdas", 
              "Asisten virtual interaktif yang siap menjawab pertanyaan, membantu penulisan kreatif, hingga memberikan saran solusi masalah. Dilengkapi dengan mode 'Fast' untuk respons instan sehari-hari dan mode 'Expert' untuk analisis mendalam, chatbot ini beradaptasi dengan kebutuhan produktivitas Anda."),
            _buildFeatureItem("Face Recognition", 
              "Sistem keamanan dan identifikasi biometrik canggih yang mampu mengenali wajah pengguna secara presisi. Fitur ini dirancang untuk personalisasi pengalaman pengguna serta meningkatkan keamanan akses aplikasi melalui teknologi pengenalan pola wajah terkini yang aman."),
            _buildFeatureItem("Object Detection", 
              "Jelajahi lingkungan sekitar dengan mata digital. Arahkan kamera ke benda apa pun, dan AI kami akan mengidentifikasi serta memberikan informasi detail mengenai objek tersebut secara real-time, membantu Anda mengenali dunia dengan cara baru."),
            _buildFeatureItem("OCR (Scan Teks)", 
              "Transformasi instan dari fisik ke digital. Pindai dokumen, papan tulis, atau catatan tangan, dan dapatkan teks digital yang bisa diedit, disalin, atau diterjemahkan dalam hitungan detik. Teknologi ini memastikan akurasi pembacaan tinggi untuk digitalisasi arsip."),
            _buildFeatureItem("Smart QR & Tools", 
              "Lebih dari sekadar pemindai kode QR biasa. Fitur ini mengintegrasikan berbagai alat bantu utilitas yang memudahkan akses informasi digital, pembayaran instan, hingga konektivitas Wi-Fi dan kontak hanya dalam satu kali pemindaian cepat dan efisien."),

            const SizedBox(height: 32),

            // --- AUTHOR / TEAM ---
            _buildSectionHeader("Tim Pengembang"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthor("Ananda Afif\nFauzan", "assets/images/afif.jpg"),
                _buildAuthor("Muhammad\nFebryadi", "assets/images/febry.jpg"),
                _buildAuthor("Lintang\nDyahayuningsih", "assets/images/lintang.jpg"),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• $title", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700], height: 1.5), textAlign: TextAlign.justify),
        ],
      ),
    );
  }

  Widget _buildAuthor(String name, String assetPath) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
            image: DecorationImage(
              image: AssetImage(assetPath),
              fit: BoxFit.cover,
              onError: (_, __) => const AssetImage('assets/images/clouds.png'), // Fallback jika gambar belum ada
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}