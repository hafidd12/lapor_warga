import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatWibDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final wib = dateTime.toUtc().add(const Duration(hours: 7));
    final day = wib.day.toString().padLeft(2, '0');
    final month = months[wib.month - 1];
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '$day $month ${wib.year}, $hour:$minute WIB';
  }

  IconData _notificationIcon(NotificationType type) {
    return switch (type) {
      NotificationType.verification => Icons.verified_user_rounded,
      NotificationType.announcement => Icons.campaign_rounded,
      NotificationType.voting => Icons.how_to_vote_rounded,
      NotificationType.votingResult => Icons.emoji_events_rounded,
      NotificationType.report => Icons.assignment_rounded,
      NotificationType.newReport => Icons.report_problem_rounded,
    };
  }

  Color _notificationColor(NotificationType type) {
    return switch (type) {
      NotificationType.verification => const Color(0xFF2563EB),
      NotificationType.announcement => AppTheme.statusMedium,
      NotificationType.voting => const Color(0xFF7C3AED),
      NotificationType.votingResult => const Color(0xFFB45309),
      NotificationType.report => AppTheme.primaryColor,
      NotificationType.newReport => AppTheme.statusHigh,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final notifications = state.notifications;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Notifikasi'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimaryColor,
            elevation: 0.5,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () =>
                    state.refreshNotifications().catchError((_) {}),
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Belum ada notifikasi',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Saat ini belum ada notifikasi untuk ditampilkan.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == notifications.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _NotificationTile(
                              notification: notification,
                              formatDateTime: _formatWibDate,
                              icon: _notificationIcon(notification.type),
                              iconColor: _notificationColor(notification.type),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String Function(DateTime) formatDateTime;
  final IconData icon;
  final Color iconColor;

  const _NotificationTile({
    required this.notification,
    required this.formatDateTime,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.outlineVariantColor.withValues(alpha: 0.55)
              : AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: AppTheme.statusHigh,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  formatDateTime(notification.createdAt),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
