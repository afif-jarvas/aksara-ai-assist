import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityItem {
  final String titleKey;
  final String descKey;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  ActivityItem({
    required this.titleKey,
    required this.descKey,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

class ActivityNotifier extends StateNotifier<List<ActivityItem>> {
  ActivityNotifier() : super([]);
  void addActivity(
      String titleKey, String descKey, IconData icon, Color color) {
    // Hindari spam log: jika activity terakhir sama persis (dalam 1 menit), jangan tambah baru
    if (state.isNotEmpty) {
      final last = state.first;
      if (last.titleKey == titleKey &&
          last.descKey == descKey &&
          DateTime.now().difference(last.timestamp).inMinutes < 1) {
        return;
      }
    }

    state = [
      ActivityItem(
        titleKey: titleKey,
        descKey: descKey,
        timestamp: DateTime.now(),
        icon: icon,
        color: color,
      ),
      ...state
    ];
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, List<ActivityItem>>(
        (ref) => ActivityNotifier());
