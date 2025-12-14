import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model untuk item aktivitas
class ActivityItem {
  final String titleKey; // Key untuk judul (misal: 'feat_face')
  final String descKey;  // Key untuk deskripsi
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  ActivityItem({
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}

// Notifier untuk mengelola state list aktivitas
class ActivityNotifier extends StateNotifier<List<ActivityItem>> {
  ActivityNotifier() : super([]);

  // Fungsi untuk menambah aktivitas baru ke paling atas list
  void addActivity(String titleKey, String descKey, IconData icon, Color color) {
    state = [
      ActivityItem(
        titleKey: titleKey,
        descKey: descKey,
        icon: icon,
        color: color,
        timestamp: DateTime.now(),
      ),
      ...state,
    ];
  }

  // Fungsi untuk menghapus semua riwayat
  void clearHistory() {
    state = [];
  }

  // Fungsi untuk menghapus satu item berdasarkan index
  void removeAt(int index) {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState.removeAt(index);
      state = newState;
    }
  }
}

// Provider global yang bisa diakses dari mana saja
final activityProvider = StateNotifierProvider<ActivityNotifier, List<ActivityItem>>((ref) {
  return ActivityNotifier();
});