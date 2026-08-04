// 선택중, 요청중, 분석중, 완료, 실패 등 화면 상태 관리

final class DiagnosisExamination {
  const DiagnosisExamination({
    required this.examId,
    required this.title,
    this.patientId,
    this.examDate,
    this.vesselType,
    this.keyFrameUrl,
    this.videoUrl,
  });

  final int examId;
  final String title;
  final String? patientId;
  final String? examDate;
  final String? vesselType;
  final String? keyFrameUrl;
  final String? videoUrl;

  bool get hasKeyFrame {    //이미지 있는지 확인
    return keyFrameUrl?.trim().isNotEmpty ?? false;
  }

  bool get hasVideo {   // 동영상 있는지 확인
    return videoUrl?.trim().isNotEmpty ?? false;
  }

  bool get canRunIntegratedAnalysis {
   return hasKeyFrame;
  }

  factory DiagnosisExamination.fromJson(
    Map<String, dynamic> json,
  ) {
    final examId = _intValue(
      json['exam_id'] ?? json['id'],
    );

    if (examId == null) {
      throw const FormatException(
        '검사 ID가 없거나 올바른 숫자 형식이 아닙니다.',
      );
    }

    final vesselType = _nullableString(
      json['vessel_type'] ??
          json['artery_name'] ??
          json['vessel_name'],
    );

    final explicitTitle = _nullableString(
      json['title'] ??
          json['exam_name'] ??
          json['examination_name'] ??
          json['view_name'],
    );

    return DiagnosisExamination(
      examId: examId,
      title: explicitTitle ??
          vesselType ??
          '검사 $examId',
      patientId: _nullableString(
        json['patient_id'] ??
            json['patientId'],
      ),
      examDate: _nullableString(
        json['exam_date'] ??
            json['examination_date'] ??
            json['created_at'],
      ),
      vesselType: vesselType,
      keyFrameUrl: _nullableString(
        json['key_frame_url'] ??
            json['image_url'] ??
            json['frame_url'] ??
            json['thumbnail_url'] ??
            json['key_frame_path'],
      ),
      videoUrl: _nullableString(
        json['video_url'] ??
            json['video_path'],
      ),
    );
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

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }
}