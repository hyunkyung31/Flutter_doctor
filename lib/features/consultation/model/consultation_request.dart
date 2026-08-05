final class ConsultationRequest {
  const ConsultationRequest({
    required this.consultationId,
    required this.patientId,
    required this.patientName,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.reason,
    required this.priority,
    required this.memo,
    required this.referenceTypes,
    required this.status,
    required this.createdAt,
    this.examId,
    this.responseMemo = '',
    this.completedAt,
  });

  final String consultationId;
  final String patientId;
  final String patientName;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String reason;
  final String priority;
  final String memo;
  final List<String> referenceTypes;
  final String status;
  final DateTime? createdAt;
  final int? examId;
  final String responseMemo;
  final DateTime? completedAt;

  bool get isPending {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus.isEmpty ||
        normalizedStatus == 'pending' ||
        normalizedStatus == 'requested' ||
        normalizedStatus == 'waiting' ||
        normalizedStatus == 'new';
  }

  bool get isInProgress {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus == 'in_progress' ||
        normalizedStatus == 'reviewing' ||
        normalizedStatus == 'processing';
  }

  bool get isCompleted {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus == 'completed' ||
        normalizedStatus == 'complete' ||
        normalizedStatus == 'answered' ||
        responseMemo.trim().isNotEmpty;
  }

  bool get isWaitingForResponse {
    return isPending || isInProgress;
  }

  ConsultationRequest copyWith({
    String? status,
    String? responseMemo,
    DateTime? completedAt,
  }) {
    return ConsultationRequest(
      consultationId: consultationId,
      patientId: patientId,
      patientName: patientName,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      reason: reason,
      priority: priority,
      memo: memo,
      referenceTypes: referenceTypes,
      status: status ?? this.status,
      createdAt: createdAt,
      examId: examId,
      responseMemo: responseMemo ?? this.responseMemo,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory ConsultationRequest.fromJson(Map<String, dynamic> json) {
    final patient = _mapValue(json['patient']);
    final sender = _mapValue(json['sender']);
    final receiver = _mapValue(json['receiver']);

    return ConsultationRequest(
      consultationId: _stringValue(
        json['consultation_id'] ??
            json['consultationId'] ??
            json['request_id'] ??
            json['id'],
      ),
      patientId: _stringValue(
        json['patient_id'] ??
            json['patientId'] ??
            patient?['patient_id'] ??
            patient?['id'],
      ),
      patientName: _stringValue(
        json['patient_name'] ??
            json['patientName'] ??
            patient?['patient_name'] ??
            patient?['name'],
      ),
      senderId: _stringValue(
        json['sender_id'] ??
            json['senderId'] ??
            json['requester_id'] ??
            sender?['doctor_id'] ??
            sender?['id'],
      ),
      senderName: _stringValue(
        json['sender_name'] ??
            json['senderName'] ??
            json['requester_name'] ??
            sender?['doctor_name'] ??
            sender?['name'],
      ),
      receiverId: _stringValue(
        json['receiver_id'] ??
            json['receiverId'] ??
            receiver?['doctor_id'] ??
            receiver?['id'],
      ),
      reason: _stringValue(json['reason']),
      priority: _stringValue(json['priority']),
      memo: _stringValue(json['memo']),
      referenceTypes: _stringListValue(
        json['reference_types'] ?? json['referenceTypes'],
      ),
      status: _stringValue(json['status'] ?? json['request_status']),
      createdAt: _dateTimeValue(json['created_at'] ?? json['createdAt']),
      examId: _intValue(json['exam_id'] ?? json['examId']),
      responseMemo: _stringValue(json['response_memo'] ?? json['responseMemo']),
      completedAt: _dateTimeValue(json['completed_at'] ?? json['completedAt']),
    );
  }

  static Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final text = _stringValue(value);

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  static DateTime? _dateTimeValue(dynamic value) {
    final text = _stringValue(value);

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<String> _stringListValue(dynamic value) {
    if (value is List) {
      return value
          .map(_stringValue)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String) {
      final normalizedValue = value.trim();

      if (normalizedValue.isEmpty) {
        return const <String>[];
      }

      return normalizedValue
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }
}
