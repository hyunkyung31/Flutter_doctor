class Patient {
  final int patientId;
  final int? primaryDoctorId;

  final String? datasetPatientId;
  final String patientName;
  final String gender;
  final int age;

  final int? historyScore;
  final String? ecgResult;
  final int? riskFactorsCount;
  final double? troponinTLevel;
  final String? underlyingDiseases;
  final String? chiefComplaint;

  final DateTime? createdAt;

  const Patient({
    required this.patientId,
    this.primaryDoctorId,
    this.datasetPatientId,
    required this.patientName,
    required this.gender,
    required this.age,
    this.historyScore,
    this.ecgResult,
    this.riskFactorsCount,
    this.troponinTLevel,
    this.underlyingDiseases,
    this.chiefComplaint,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: _toInt(json['patient_id']) ?? 0,
      primaryDoctorId: _toInt(json['primary_doctor_id']),

      datasetPatientId: json['dataset_patient_id']?.toString(),
      patientName: json['patient_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: _toInt(json['age']) ?? 0,

      historyScore: _toInt(json['history_score']),
      ecgResult: json['ecg_result']?.toString(),
      riskFactorsCount: _toInt(json['risk_factors_count']),
      troponinTLevel: _toDouble(json['troponin_t_level']),
      underlyingDiseases: json['underlying_diseases']?.toString(),
      chiefComplaint: json['chief_complaint']?.toString(),

      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String get genderText {
    switch (gender.toUpperCase()) {
      case 'M':
      case 'MALE':
      case '남성':
        return '남성';

      case 'F':
      case 'FEMALE':
      case '여성':
        return '여성';

      default:
        return gender;
    }
  }
}