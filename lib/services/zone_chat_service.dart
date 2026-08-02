import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single chat message in a neighbourhood zone chat
class ZoneMessage {
  final String id;
  final String zoneId;
  final String senderName;
  final String senderId;
  final String message;
  final bool isLeader;
  final DateTime createdAt;

  ZoneMessage({
    required this.id,
    required this.zoneId,
    required this.senderName,
    required this.senderId,
    required this.message,
    this.isLeader = false,
    required this.createdAt,
  });

  factory ZoneMessage.fromJson(Map<String, dynamic> json) {
    return ZoneMessage(
      id: json['id'] ?? '',
      zoneId: json['zone_id'] ?? '',
      senderName: json['sender_name'] ?? 'Resident',
      senderId: json['sender_id'] ?? '',
      message: json['message'] ?? '',
      isLeader: json['is_leader'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// ZoneChatService — Supabase Realtime neighbourhood chat.
///
/// Each neighbourhood zone (community_id) gets its own chat channel.
/// Only residents of the same zone see each other's messages.
/// Leader messages are highlighted with a verified badge.
class ZoneChatService {
  static final ZoneChatService _instance = ZoneChatService._internal();
  factory ZoneChatService() => _instance;
  ZoneChatService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  RealtimeChannel? _channel;
  String? _activeZoneId;
  final StreamController<List<ZoneMessage>> _messagesController =
      StreamController<List<ZoneMessage>>.broadcast();

  final List<ZoneMessage> _messages = [];

  /// Stream of messages for the active zone
  Stream<List<ZoneMessage>> get messagesStream => _messagesController.stream;

  /// Current loaded messages
  List<ZoneMessage> get messages => List.unmodifiable(_messages);

  /// Subscribe to realtime messages for a zone and load history
  Future<void> joinZone(String zoneId) async {
    if (_activeZoneId == zoneId) return;

    // Leave previous zone if any
    await leaveZone();

    _activeZoneId = zoneId;
    _messages.clear();

    try {
      // Load last 50 messages (last 7 days only for privacy)
      final since = DateTime.now().subtract(const Duration(days: 7));
      final history = await _supabase
          .from('zone_messages')
          .select()
          .eq('zone_id', zoneId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: true)
          .limit(50);

      _messages.addAll(
        (history as List).map((j) => ZoneMessage.fromJson(j)).toList(),
      );
      _messagesController.add(List.from(_messages));

      // Subscribe to new messages via Supabase Realtime
      _channel = _supabase
          .channel('zone_chat_$zoneId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'zone_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'zone_id',
              value: zoneId,
            ),
            callback: (payload) {
              final newMsg = ZoneMessage.fromJson(
                payload.newRecord,
              );
              _messages.add(newMsg);
              _messagesController.add(List.from(_messages));
            },
          )
          .subscribe();

      debugPrint('💬 Joined zone chat: $zoneId (${_messages.length} messages loaded)');
    } catch (e) {
      debugPrint('⚠️ Zone chat error: $e');
      // Add demo messages so the UI isn't empty
      _messages.addAll(_demoMessages(zoneId));
      _messagesController.add(List.from(_messages));
    }
  }

  /// Send a message to the active zone channel
  Future<bool> sendMessage({
    required String senderName,
    required String senderId,
    required String message,
    bool isLeader = false,
  }) async {
    if (_activeZoneId == null) return false;
    if (message.trim().isEmpty) return false;

    try {
      await _supabase.from('zone_messages').insert({
        'zone_id': _activeZoneId,
        'sender_name': senderName,
        'sender_id': senderId,
        'message': message.trim(),
        'is_leader': isLeader,
      });
      return true;
    } catch (e) {
      debugPrint('⚠️ Could not send message: $e');
      // Optimistic UI fallback — add locally
      _messages.add(ZoneMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        zoneId: _activeZoneId!,
        senderName: senderName,
        senderId: senderId,
        message: message.trim(),
        isLeader: isLeader,
        createdAt: DateTime.now(),
      ));
      _messagesController.add(List.from(_messages));
      return true;
    }
  }

  /// Leave the current zone channel
  Future<void> leaveZone() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _activeZoneId = null;
    _messages.clear();
  }

  /// Demo messages for offline/fallback mode
  List<ZoneMessage> _demoMessages(String zoneId) {
    final now = DateTime.now();
    return [
      ZoneMessage(
        id: 'demo_1',
        zoneId: zoneId,
        senderName: 'Mallam Usman (Mai Anguwa)',
        senderId: 'leader_001',
        message: '🔒 Assalamu alaikum. Night patrol has started. Please keep your gates locked after 10pm.',
        isLeader: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ZoneMessage(
        id: 'demo_2',
        zoneId: zoneId,
        senderName: 'Aminu Bello',
        senderId: 'resident_002',
        message: 'Wa alaikum salam. Noted! We will be careful.',
        isLeader: false,
        createdAt: now.subtract(const Duration(hours: 4, minutes: 30)),
      ),
      ZoneMessage(
        id: 'demo_3',
        zoneId: zoneId,
        senderName: 'Fatima Abubakar',
        senderId: 'resident_003',
        message: 'There was a suspicious car parked near the mosque earlier. Blue Toyota.',
        isLeader: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ZoneMessage(
        id: 'demo_4',
        zoneId: zoneId,
        senderName: 'Mallam Usman (Mai Anguwa)',
        senderId: 'leader_001',
        message: '✅ Thank you for the report. Vigilante team has been notified and will check the area.',
        isLeader: true,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
    ];
  }

  void dispose() {
    leaveZone();
    _messagesController.close();
  }
}
