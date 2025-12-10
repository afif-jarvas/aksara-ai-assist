import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static RealtimeChannel getChannel(String channelName) {
    return client.channel(channelName);
  }
  
  static Future<void> publishRealtimeEvent(
    String channelName,
    String eventName,
    Map<String, dynamic> payload,
  ) async {
    try {
      final channel = getChannel(channelName);
      await channel.subscribe();
      // Send broadcast message - simplified approach
      // Note: Realtime publishing is mainly done from Edge Functions
      // This is a placeholder for client-side publishing if needed
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Silently fail - realtime publishing is handled by Edge Functions
      print('Realtime publish error (non-critical): $e');
    }
  }
  
  static Stream<Map<String, dynamic>> subscribeToChannel(
    String channelName,
    String eventName,
  ) {
    final channel = getChannel(channelName);
    channel.subscribe();
    
    final controller = StreamController<Map<String, dynamic>>();
    
    channel.onBroadcast(
      event: eventName,
      callback: (payload, [ref]) {
        if (payload is Map<String, dynamic>) {
          controller.add(payload);
        }
      },
    );
    
    return controller.stream;
  }
}


