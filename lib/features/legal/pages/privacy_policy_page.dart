import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kebijakan Privasi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Terakhir diperbarui: Desember 2025", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            
            _buildPolicyPoint(
              "1. Pengumpulan Data Pengguna", 
              "Kami mengumpulkan informasi yang Anda berikan secara langsung saat menggunakan aplikasi, seperti data profil (nama, email), gambar yang diunggah untuk analisis AI, dan riwayat percakapan dengan chatbot. Kami juga dapat mengumpulkan data teknis seperti alamat IP dan jenis perangkat semata-mata untuk keperluan diagnostik dan perbaikan bug."
            ),
            _buildPolicyPoint(
              "2. Penggunaan Informasi", 
              "Data yang kami kumpulkan digunakan sepenuhnya untuk menyediakan, memelihara, dan meningkatkan layanan Aksara AI. Informasi sensitif seperti gambar wajah atau teks hasil OCR diproses secara real-time oleh sistem AI kami dan tidak digunakan untuk tujuan komersial di luar fungsionalitas inti aplikasi ini."
            ),
            _buildPolicyPoint(
              "3. Keamanan Data", 
              "Keamanan data Anda adalah prioritas utama kami. Kami menerapkan langkah-langkah keamanan teknis standar industri, termasuk enkripsi data saat transmisi (SSL/TLS) dan penyimpanan yang aman pada server database kami, untuk melindungi informasi pribadi Anda dari akses, pengungkapan, atau penyalahgunaan yang tidak sah."
            ),
            _buildPolicyPoint(
              "4. Layanan Pihak Ketiga", 
              "Aksara AI mungkin menggunakan layanan pihak ketiga terpercaya (seperti penyedia layanan cloud atau API pemrosesan AI) untuk memproses data tertentu. Pihak ketiga ini terikat oleh kewajiban kerahasiaan yang ketat dan hanya memproses data sesuai instruksi kami untuk keperluan operasional aplikasi."
            ),
            _buildPolicyPoint(
              "5. Hak Pengguna", 
              "Sebagai pengguna, Anda memiliki kendali penuh atas data Anda. Anda berhak untuk mengakses, memperbaiki, atau meminta penghapusan permanen data pribadi Anda yang tersimpan di sistem kami kapan saja. Jika Anda memiliki pertanyaan atau kekhawatiran mengenai privasi, Anda dapat menghubungi tim dukungan kami melalui menu pengaturan."
            ),
            
            const SizedBox(height: 40),
            Center(child: Text("© 2025 Aksara AI Team", style: TextStyle(color: Colors.grey[400]))),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyPoint(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: Colors.black87), textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}