/// Django Appointment 상태와 동일
enum AppointmentStatus {
  requested,
  confirmed,
  cancelled,
  completed,
}

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.requested:
        return '신청';
      case AppointmentStatus.confirmed:
        return '확정';
      case AppointmentStatus.cancelled:
        return '취소';
      case AppointmentStatus.completed:
        return '완료';
    }
  }

  static AppointmentStatus fromName(String? raw) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == (raw ?? '').toLowerCase(),
      orElse: () => AppointmentStatus.requested,
    );
  }
}

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

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String department;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == AppointmentStatus.requested ||
      status == AppointmentStatus.confirmed;

  bool get canConfirm => status == AppointmentStatus.requested;

  bool get canComplete => status == AppointmentStatus.confirmed;

  bool get canCancel =>
      status == AppointmentStatus.requested ||
      status == AppointmentStatus.confirmed;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic raw) {
      return (DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now())
          .toLocal();
    }

    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ??
          json['patientId']?.toString() ??
          '',
      patientName: json['patient_name']?.toString() ??
          json['patientName']?.toString() ??
          '',
      doctorId: json['doctor_id']?.toString() ??
          json['doctorId']?.toString() ??
          '',
      doctorName: json['doctor_name']?.toString() ??
          json['doctorName']?.toString() ??
          '',
      department: json['department']?.toString() ?? '',
      scheduledAt: parseDt(json['scheduled_at'] ?? json['scheduledAt']),
      status: AppointmentStatusX.fromName(json['status']?.toString()),
      memo: json['memo']?.toString() ?? '',
      createdAt: parseDt(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDt(json['updated_at'] ?? json['updatedAt']),
    );
  }
}
