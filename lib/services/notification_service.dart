import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'supabase_service.dart';

class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationService {
  NotificationService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const String _selectColumns =
      'id, recipient_id, sender_id, title, message, type, related_table, related_id, is_read, created_at';

  Future<void> createNotification({
    String? userId,
    String? recipientId,
    String? senderId,
    required NotificationType type,
    String? title,
    String? message,
    String? relatedTable,
    String? relatedId,
    bool isRead = false,
    DateTime? createdAt,
  }) async {
    final normalizedRecipientId = (recipientId ?? userId ?? '').trim();
    if (normalizedRecipientId.isEmpty) {
      throw const NotificationServiceException('Recipient ID not found.');
    }

    final normalizedTitle = title?.trim() ?? '';
    final normalizedMessage = message?.trim() ?? '';
    final now = (createdAt ?? DateTime.now()).toUtc().toIso8601String();
    final normalizedSenderId = senderId?.trim() ?? '';

    final payload = <String, dynamic>{
      'recipient_id': normalizedRecipientId,
      if (normalizedSenderId.isNotEmpty) 'sender_id': normalizedSenderId,
      'type': _typeValue(type),
      'title': normalizedTitle.isNotEmpty
          ? normalizedTitle
          : _defaultTitle(type),
      'message': normalizedMessage,
      'related_table': _normalizedValue(relatedTable),
      'related_id': _normalizedValue(relatedId),
      'is_read': isRead,
      'created_at': now,
    };

    debugPrint('[NotificationService] createNotification payload=$payload');

    await _client.from('notifications').insert(payload);
  }

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final normalizedRecipientId = userId.trim();
    if (normalizedRecipientId.isEmpty) {
      return const [];
    }

    final rows = await _client
        .from('notifications')
        .select(_selectColumns)
        .eq('recipient_id', normalizedRecipientId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => AppNotification.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) {
      throw const NotificationServiceException('Notification ID not found.');
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', normalizedId);
  }

  Future<void> markAllAsRead(String userId) async {
    final normalizedRecipientId = userId.trim();
    if (normalizedRecipientId.isEmpty) {
      throw const NotificationServiceException('Recipient ID not found.');
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', normalizedRecipientId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) {
      throw const NotificationServiceException('Notification ID not found.');
    }

    await _client.from('notifications').delete().eq('id', normalizedId);
  }

  String _typeValue(NotificationType type) {
    return switch (type) {
      NotificationType.verification => 'verification',
      NotificationType.announcement => 'announcement',
      NotificationType.voting => 'voting',
      NotificationType.votingResult => 'voting_result',
      NotificationType.report => 'report',
      NotificationType.newReport => 'new_report',
    };
  }

  String _defaultTitle(NotificationType type) {
    return switch (type) {
      NotificationType.verification => 'Verifikasi akun',
      NotificationType.announcement => 'Pengumuman baru',
      NotificationType.voting => 'Voting baru dibuka',
      NotificationType.votingResult => 'Hasil voting tersedia',
      NotificationType.report => 'Status laporan berubah',
      NotificationType.newReport => 'Laporan baru masuk',
    };
  }

  String? _normalizedValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
