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

  bool get isPending {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus.isEmpty ||
        normalizedStatus == 'pending' ||
        normalizedStatus == 'requested' ||
        normalizedStatus == 'waiting' ||
        normalizedStatus == 'new';
  }

  ConsultationRequest copyWith({String? status}) {
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
      createdAt: DateTime.tryParse(
        _stringValue(json['created_at'] ?? json['createdAt']),
      ),
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

  static List<String> _stringListValue(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map(_stringValue)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
