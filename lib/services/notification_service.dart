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
      'id, user_id, type, title, message, body, description, content, is_read, created_at, read_at, target_id, target_type, related_id, related_type';

  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    String? title,
    String? message,
    String? targetId,
    String? targetType,
    bool isRead = false,
    DateTime? createdAt,
    DateTime? readAt,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const NotificationServiceException('User ID not found.');
    }

    final normalizedTitle = title?.trim() ?? '';
    final normalizedMessage = message?.trim() ?? '';
    final now = (createdAt ?? DateTime.now()).toUtc().toIso8601String();
    final resolvedReadAt = isRead
        ? (readAt ?? DateTime.now()).toUtc().toIso8601String()
        : readAt?.toUtc().toIso8601String();

    final payload = <String, dynamic>{
      'user_id': normalizedUserId,
      'type': _typeValue(type),
      'title': normalizedTitle.isNotEmpty
          ? normalizedTitle
          : _defaultTitle(type),
      'message': normalizedMessage,
      'is_read': isRead,
      'created_at': now,
      'read_at': resolvedReadAt,
      'target_id': _normalizedValue(targetId),
      'target_type': _normalizedValue(targetType),
    };

    debugPrint('[NotificationService] createNotification payload=$payload');

    await _client.from('notifications').insert(payload);
  }

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const [];
    }

    final rows = await _client
        .from('notifications')
        .select(_selectColumns)
        .eq('user_id', normalizedUserId)
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
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', normalizedId);
  }

  Future<void> markAllAsRead(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const NotificationServiceException('User ID not found.');
    }

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', normalizedUserId)
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
