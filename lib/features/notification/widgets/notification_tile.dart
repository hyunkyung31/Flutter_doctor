import 'package:flutter/material.dart';

import '../model/app_notification.dart';

final class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = _metadata(notification.type);

    return Material(
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withValues(alpha: 0.34),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: metadata.backgroundColor(colorScheme),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  metadata.icon,
                  color: metadata.foregroundColor(colorScheme),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isEmpty
                                ? '새 알림'
                                : notification.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

_NotificationMetadata _metadata(AppNotificationType type) {
  if (type.isConsultation) {
    return const _NotificationMetadata(Icons.groups_outlined, _Tone.primary);
  }
  if (type == AppNotificationType.chatMessage) {
    return const _NotificationMetadata(
      Icons.chat_bubble_outline,
      _Tone.primary,
    );
  }
  if (type == AppNotificationType.sharedResource) {
    return const _NotificationMetadata(Icons.attach_file, _Tone.secondary);
  }
  if (type == AppNotificationType.appointmentRequested) {
    return const _NotificationMetadata(
      Icons.calendar_month_outlined,
      _Tone.tertiary,
    );
  }

  if (type == AppNotificationType.appointmentRequested) {
    return const _NotificationMetadata(
      Icons.calendar_month_outlined,
      _Tone.tertiary,
    );
  }
  if (type == AppNotificationType.clinicalReportReady) {
    return const _NotificationMetadata(
      Icons.description_outlined,
      _Tone.secondary,
    );
  }
  return const _NotificationMetadata(Icons.notifications_none, _Tone.neutral);
}

String _relativeTime(DateTime value) {
  if (value.millisecondsSinceEpoch == 0) return '';

  final local = value.toLocal();
  final difference = DateTime.now().difference(local);

  if (difference.isNegative || difference.inMinutes < 1) return '방금 전';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전';
  if (difference.inDays < 1) return '${difference.inHours}시간 전';
  if (difference.inDays < 7) return '${difference.inDays}일 전';

  return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
}

enum _Tone { primary, secondary, tertiary, neutral }

final class _NotificationMetadata {
  const _NotificationMetadata(this.icon, this.tone);

  final IconData icon;
  final _Tone tone;

  Color backgroundColor(ColorScheme colors) => switch (tone) {
    _Tone.primary => colors.primaryContainer,
    _Tone.secondary => colors.secondaryContainer,
    _Tone.tertiary => colors.tertiaryContainer,
    _Tone.neutral => colors.surfaceContainerHighest,
  };

  Color foregroundColor(ColorScheme colors) => switch (tone) {
    _Tone.primary => colors.onPrimaryContainer,
    _Tone.secondary => colors.onSecondaryContainer,
    _Tone.tertiary => colors.onTertiaryContainer,
    _Tone.neutral => colors.onSurfaceVariant,
  };
}
