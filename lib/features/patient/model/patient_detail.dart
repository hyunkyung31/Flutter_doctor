import 'patient.dart';

final class PatientDetail {
  const PatientDetail({
    required this.patient,
    required this.examinations,
    required this.aiResults,
  });

  final Patient patient;
  final List<Map<String, dynamic>> examinations;
  final List<Map<String, dynamic>> aiResults;

  factory PatientDetail.fromJson(Map<String, dynamic> json) {
    final patientData = json['patient'];

    if (patientData is! Map) {
      throw const FormatException('환자 기본정보 형식이 올바르지 않습니다.');
    }

    return PatientDetail(
      patient: Patient.fromJson(Map<String, dynamic>.from(patientData)),
      examinations: _mapListValue(json['examinations']),
      aiResults: _mapListValue(json['ai_results'] ?? json['aiResults']),
    );
  }

  static List<Map<String, dynamic>> _mapListValue(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
