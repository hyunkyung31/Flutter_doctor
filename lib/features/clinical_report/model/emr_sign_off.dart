final class EmrSignOff {
  const EmrSignOff({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.finalized,
    required this.finalResult,
    required this.emrTransmitted,
    required this.reportReady,
    this.reportUrl,
    this.reportGeneratedAt,
    this.aiResult,
    this.transmittedAt,
    this.createdAt,
    this.updatedAt,
    this.aiSummary = '',
    this.xaiExplanation = '',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final bool finalized;
  final String finalResult;
  final EmrAiResultReference? aiResult;
  final bool emrTransmitted;
  final DateTime? transmittedAt;
  final bool reportReady;
  // JWT 인증을 통해 접근하는 보호된 PDF 다운로드 API 경로
  final String? reportUrl;
  // 서버에서 PDF 생성이 완료된 시각
  final DateTime? reportGeneratedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String aiSummary;
  final String xaiExplanation;

  factory EmrSignOff.fromJson(Map<String, dynamic> json) {
    return EmrSignOff(
      id: _requiredIdentifier(json['id'], fieldName: 'id'),
      patientId: _requiredIdentifier(
        json['patient_id'],
        fieldName: 'patient_id',
      ),
      doctorId: _requiredIdentifier(json['doctor_id'], fieldName: 'doctor_id'),
      finalized: _boolValue(json['finalized']),
      finalResult: _stringValue(json['final_result']),
      aiResult: EmrAiResultReference.tryParse(json['ai_result']),
      emrTransmitted: _boolValue(json['emr_transmitted']),
      transmittedAt: _dateTimeValue(json['transmitted_at']),
      reportReady: _boolValue(json['report_ready']),
      reportUrl: _nullableStringValue(json['report_url']),
      reportGeneratedAt: _dateTimeValue(json['report_generated_at']),
      createdAt: _dateTimeValue(json['created_at']),
      updatedAt: _dateTimeValue(json['updated_at']),
      aiSummary: json['ai_summary']?.toString() ?? '',
      xaiExplanation: json['xai_explanation']?.toString() ?? '',
    );
  }

  static String _requiredIdentifier(
    Object? value, {
    required String fieldName,
  }) {
    final identifier = _nullableStringValue(value);

    if (identifier == null) {
      throw FormatException('EMR 서명 응답에 $fieldName 값이 없습니다.');
    }

    return identifier;
  }

  static String _stringValue(Object? value) {
    return _nullableStringValue(value) ?? '';
  }

  static String? _nullableStringValue(Object? value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalizedValue = value.trim().toLowerCase();

      return normalizedValue == 'true' || normalizedValue == '1';
    }

    return false;
  }

  static DateTime? _dateTimeValue(Object? value) {
    final text = _nullableStringValue(value);

    if (text == null) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}

final class EmrAiResultReference {
  const EmrAiResultReference({this.id, this.examId, this.data});

  final String? id;
  final int? examId;
  final Map<String, dynamic>? data;

  static EmrAiResultReference? tryParse(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      final json = Map<String, dynamic>.from(value);

      return EmrAiResultReference(
        id: _nullableStringValue(json['id'] ?? json['ai_result_id']),
        examId: _intValue(json['exam_id']),
        data: Map<String, dynamic>.unmodifiable(json),
      );
    }

    final id = _nullableStringValue(value);

    if (id == null) {
      return null;
    }

    return EmrAiResultReference(id: id);
  }

  static String? _nullableStringValue(Object? value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }
}
