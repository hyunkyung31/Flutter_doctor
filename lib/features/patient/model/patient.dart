final class Patient {
  const Patient({
    required this.patientId,
    required this.patientName,
    required this.gender,
    required this.age,
    this.primaryDoctorId,
    this.chiefComplaint,
    this.ecgResult,
    this.ecgImageUrl,
    this.troponinTLevel,
    this.historyScore,
    this.riskFactorsCount,
    this.latestSeverityClass,
    this.hasLesion,
  });

  final String patientId;
  final String patientName;
  final String gender;
  final int age;
  final String? primaryDoctorId;
  final String? chiefComplaint;
  final String? ecgResult;
  final String? ecgImageUrl;
  final double? troponinTLevel;
  final int? historyScore;
  final int? riskFactorsCount;
  final String? latestSeverityClass;
  final dynamic hasLesion;

  factory Patient.fromJson(
    Map<String, dynamic> json,
  ) {
    return Patient(
      patientId:
          json['patient_id']?.toString() ?? '',
      patientName:
          json['patient_name']?.toString() ??
              '이름 없음',
      gender: json['gender']?.toString() ?? '',
      age: _toInt(json['age']) ?? 0,
      primaryDoctorId:
          json['primary_doctor_id']?.toString(),
      chiefComplaint:
          json['chief_complaint']?.toString(),
      ecgResult:
          json['ecg_result']?.toString(),
      ecgImageUrl:
          json['ecg_image_url']?.toString(),
      troponinTLevel:
          _toDouble(json['troponin_t_level']),
      historyScore:
          _toInt(json['history_score']),
      riskFactorsCount:
          _toInt(json['risk_factors_count']),
      latestSeverityClass:
          json['latest_severity_class']
              ?.toString(),
      hasLesion: json['has_lesion'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String get genderText {
    final value = gender.toUpperCase();

    if (value == 'M' ||
        value == 'MALE' ||
        gender == '남성') {
      return '남성';
    }

    if (value == 'F' ||
        value == 'FEMALE' ||
        gender == '여성') {
      return '여성';
    }

    return gender.isEmpty ? '미등록' : gender;
  }
}