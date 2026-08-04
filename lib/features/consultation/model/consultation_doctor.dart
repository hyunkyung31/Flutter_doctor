final class ConsultationDoctor {
  const ConsultationDoctor({
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.hospitalName,
  });

  final String doctorId;
  final String doctorName;
  final String department;
  final String hospitalName;

  factory ConsultationDoctor.fromJson(Map<String, dynamic> json) {
    return ConsultationDoctor(
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      hospitalName: json['hospital_name']?.toString() ?? '',
    );
  }
}
