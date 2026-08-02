final class Patient {
  const Patient({
    required this.patientId,
    required this.patientName,
    required this.gender,
    required this.age,
    required this.primaryDoctorId,
    required this.chiefComplaint,
    required this.ecgResult,
    required this.ecgImageUrl,
    required this.troponinTLevel,
    required this.historyScore,
    required this.riskFactorsCount,
  });

  final String patientId;
  final String patientName;
  final String gender;
  final int age;

  final String? primaryDoctorId;
  final String? chiefComplaint;
  final String? ecgResult;

  // Swagger에서 필수값으로 표시됨
  final String ecgImageUrl;

  final double? troponinTLevel;
  final double? historyScore;
  final int? riskFactorsCount;

  String get genderText {
    final normalizedGender =
        gender.trim().toUpperCase();

    switch (normalizedGender) {
      case 'M':
      case 'MALE':
      case '남':
      case '남성':
        return '남성';

      case 'F':
      case 'FEMALE':
      case '여':
      case '여성':
        return '여성';

      default:
        return gender.trim().isEmpty
            ? '미등록'
            : gender.trim();
    }
  }

  String get troponinTText {
    final value = troponinTLevel;

    if (value == null) {
      return '미등록';
    }

    return '$value ng/L';
  }

  String get historyScoreText {
    final value = historyScore;

    if (value == null) {
      return '미등록';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String get riskFactorsCountText {
    final value = riskFactorsCount;

    if (value == null) {
      return '미등록';
    }

    return '$value개';
  }

  factory Patient.fromJson(
    Map<String, dynamic> json,
  ) {
    return Patient(
      patientId: _stringValue(
        json['patient_id'] ??
            json['patientId'] ??
            json['id'],
      ),
      patientName: _stringValue(
        json['patient_name'] ??
            json['patientName'] ??
            json['name'],
      ),
      gender: _stringValue(
        json['gender'] ??
            json['sex'],
      ),
      age: _intValue(
        json['age'],
      ),
      primaryDoctorId: _nullableStringValue(
        json['primary_doctor_id'] ??
            json['primaryDoctorId'],
      ),
      chiefComplaint: _nullableStringValue(
        json['chief_complaint'] ??
            json['chiefComplaint'],
      ),
      ecgResult: _nullableStringValue(
        json['ecg_result'] ??
            json['ecgResult'],
      ),
      ecgImageUrl: _stringValue(
        json['ecg_image_url'] ??
            json['ecgImageUrl'],
      ),
      troponinTLevel: _doubleValue(
        json['troponin_t_level'] ??
            json['troponinTLevel'],
      ),
      historyScore: _doubleValue(
        json['history_score'] ??
            json['historyScore'],
      ),
      riskFactorsCount: _nullableIntValue(
        json['risk_factors_count'] ??
            json['riskFactorsCount'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'gender': gender,
      'age': age,
      'primary_doctor_id': primaryDoctorId,
      'chief_complaint': chiefComplaint,
      'ecg_result': ecgResult,
      'ecg_image_url': ecgImageUrl,
      'troponin_t_level': troponinTLevel,
      'history_score': historyScore,
      'risk_factors_count': riskFactorsCount,
    };
  }

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static String? _nullableStringValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result =
        value.toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  static int _intValue(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int? _nullableIntValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double? _doubleValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}