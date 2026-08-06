final class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.scheduledAt,
    required this.status,
    required this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String department;
  final DateTime scheduledAt;
  final String status;
  final String memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRequested => _normalizedStatus == 'requested';
  bool get isConfirmed => _normalizedStatus == 'confirmed';
  bool get isCancelled => _normalizedStatus == 'cancelled';
  bool get isCompleted => _normalizedStatus == 'completed';

  bool get isActive => isRequested || isConfirmed;

  String get statusLabel {
    return switch (_normalizedStatus) {
      'requested' => '신청',
      'confirmed' => '확정',
      'cancelled' => '취소',
      'completed' => '완료',
      _ => status.trim().isEmpty ? '미정' : status.trim(),
    };
  }

  String get _normalizedStatus => status.trim().toLowerCase();

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: _intValue(json['id'] ?? json['appointment_id']),
      patientId: _stringValue(
        json['patient_id'] ?? json['patientId'],
      ),
      patientName: _stringValue(
        json['patient_name'] ?? json['patientName'],
      ),
      doctorId: _stringValue(
        json['doctor_id'] ?? json['doctorId'],
      ),
      doctorName: _stringValue(
        json['doctor_name'] ?? json['doctorName'],
      ),
      department: _stringValue(json['department']),
      scheduledAt: _dateTimeValue(
        json['scheduled_at'] ?? json['scheduledAt'],
      ),
      status: _stringValue(json['status']),
      memo: _stringValue(json['memo']),
      createdAt: _dateTimeValue(
        json['created_at'] ?? json['createdAt'],
      ),
      updatedAt: _dateTimeValue(
        json['updated_at'] ?? json['updatedAt'],
      ),
    );
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static DateTime _dateTimeValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
