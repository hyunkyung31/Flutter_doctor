enum NotificationCategory {
  all,
  consultation,
  chat,
  appointment,
  other;

  String get label => switch (this) {
    NotificationCategory.all => '전체',
    NotificationCategory.consultation => '협진',
    NotificationCategory.chat => '채팅',
    NotificationCategory.appointment => '예약',
    NotificationCategory.other => '기타',
  };
}

enum AppNotificationType {
  consultationCreated,
  consultationInProgress,
  consultationAccepted,
  consultationRejected,
  consultationCompleted,
  chatMessage,
  sharedResource,
  appointmentRequested,
  clinicalReportReady,
  unknown;

  static AppNotificationType fromApi(String value) {
    switch (value) {
      case 'consultation_created':
        return AppNotificationType.consultationCreated;
      case 'consultation_in_progress':
        return AppNotificationType.consultationInProgress;
      case 'consultation_accepted':
        return AppNotificationType.consultationAccepted;
      case 'consultation_rejected':
        return AppNotificationType.consultationRejected;
      case 'consultation_completed':
        return AppNotificationType.consultationCompleted;
      case 'chat_message':
        return AppNotificationType.chatMessage;
      case 'shared_resource':
        return AppNotificationType.sharedResource;
      case 'appointment_requested':
        return AppNotificationType.appointmentRequested;
      case 'clinical_report_ready':
        return AppNotificationType.clinicalReportReady;
      default:
        return AppNotificationType.unknown;
    }
  }

  bool get isConsultation => switch (this) {
    AppNotificationType.consultationCreated ||
    AppNotificationType.consultationInProgress ||
    AppNotificationType.consultationAccepted ||
    AppNotificationType.consultationRejected ||
    AppNotificationType.consultationCompleted => true,
    _ => false,
  };

  bool get isChat =>
      this == AppNotificationType.chatMessage ||
      this == AppNotificationType.sharedResource;

  NotificationCategory get category {
    if (isConsultation) {
      return NotificationCategory.consultation;
    }
    if (isChat) {
      return NotificationCategory.chat;
    }
    if (this == AppNotificationType.appointmentRequested) {
      return NotificationCategory.appointment;
    }
    return NotificationCategory.other;
  }
}

final class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.rawType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.consultationId,
    this.chatRoomId,
    this.chatMessageId,
    this.readAt,
  });

  final int id;
  final AppNotificationType type;
  final String rawType;
  final String title;
  final String message;
  final String? consultationId;
  final String? chatRoomId;
  final String? chatMessageId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationCategory get category {
    final mappedCategory = type.category;

    if (mappedCategory != NotificationCategory.other) {
      return mappedCategory;
    }

    final normalizedType = rawType.trim().toLowerCase();

    if (consultationId != null || normalizedType.startsWith('consultation_')) {
      return NotificationCategory.consultation;
    }

    if (chatRoomId != null ||
        normalizedType.startsWith('chat_') ||
        normalizedType == 'shared_resource') {
      return NotificationCategory.chat;
    }

    if (normalizedType.startsWith('appointment_')) {
      return NotificationCategory.appointment;
    }

    return NotificationCategory.other;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = _string(json['type'] ?? json['notification_type']);
    final createdAt = DateTime.tryParse(_string(json['created_at']));

    return AppNotification(
      id: _integer(json['id']),
      type: AppNotificationType.fromApi(rawType),
      rawType: rawType,
      title: _string(json['title']),
      message: _string(json['message'] ?? json['body']),
      consultationId: _nullableString(json['consultation_id']),
      chatRoomId: _nullableString(json['chat_room_id']),
      chatMessageId: _nullableString(json['chat_message_id']),
      isRead: json['is_read'] == true,
      readAt: DateTime.tryParse(_string(json['read_at'])),
      createdAt:
          createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      rawType: rawType,
      title: title,
      message: message,
      consultationId: consultationId,
      chatRoomId: chatRoomId,
      chatMessageId: chatMessageId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

int _integer(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _string(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : text;
}
