enum ChatMessageType { text, patient, examination, aiResult, consultation }

enum SharedResourceStatus { unread, checked, answered }

final class ChatDoctor {
  const ChatDoctor({
    required this.id,
    required this.name,
    required this.department,
    required this.hospital,
  });

  final String id;
  final String name;
  final String department;
  final String hospital;

  factory ChatDoctor.fromJson(Map<String, dynamic> json) {
    return ChatDoctor(
      id: (json['doctor_id'] ?? json['id'] ?? '').toString(),
      name: (json['doctor_name'] ?? json['name'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      hospital: (json['hospital_name'] ?? json['hospital'] ?? '').toString(),
    );
  }
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.type = ChatMessageType.text,
    this.patientId,
    this.patientName,
    this.examId,
    this.aiResultId,
    this.consultationId,
    this.isRead = false,
    this.resourceStatus,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final ChatMessageType type;
  final String? patientId;
  final String? patientName;
  final int? examId;
  final int? aiResultId;
  final int? consultationId;
  final bool isRead;
  final SharedResourceStatus? resourceStatus;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    final patientMap = patient is Map ? Map<String, dynamic>.from(patient) : null;
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      sentAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      type: _messageType(json['message_type']),
      patientId: _nullableString(json['patient_id']),
      patientName: _nullableString(
        patientMap?['patient_name'] ?? json['patient_name'],
      ),
      examId: _nullableInt(json['exam_id']),
      aiResultId: _nullableInt(json['ai_result_id']),
      consultationId: _nullableInt(json['consultation_id']),
      isRead: json['is_read'] == true,
      resourceStatus: _resourceStatus(json['resource_status']),
    );
  }

  static ChatMessageType _messageType(dynamic value) {
    return switch (value?.toString()) {
      'patient' => ChatMessageType.patient,
      'examination' => ChatMessageType.examination,
      'ai_result' => ChatMessageType.aiResult,
      'consultation' => ChatMessageType.consultation,
      _ => ChatMessageType.text,
    };
  }

  static SharedResourceStatus? _resourceStatus(dynamic value) {
    return switch (value?.toString()) {
      'unread' => SharedResourceStatus.unread,
      'checked' => SharedResourceStatus.checked,
      'answered' => SharedResourceStatus.answered,
      _ => null,
    };
  }

  static String? _nullableString(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

final class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.doctor,
    required this.messages,
    this.unreadCount = 0,
  });

  final String id;
  final ChatDoctor doctor;
  final List<ChatMessage> messages;
  final int unreadCount;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final doctor = json['other_doctor'];
    final lastMessage = json['last_message'];
    return ChatRoom(
      id: (json['id'] ?? '').toString(),
      doctor: ChatDoctor.fromJson(
        doctor is Map
            ? Map<String, dynamic>.from(doctor)
            : const <String, dynamic>{},
      ),
      messages: lastMessage is Map
          ? [ChatMessage.fromJson(Map<String, dynamic>.from(lastMessage))]
          : const [],
      unreadCount: ChatMessage._nullableInt(json['unread_count']) ?? 0,
    );
  }

  ChatRoom copyWith({List<ChatMessage>? messages, int? unreadCount}) {
    return ChatRoom(
      id: id,
      doctor: doctor,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
