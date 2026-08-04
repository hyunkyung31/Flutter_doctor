final class IntegratedAnalysisResult {
  const IntegratedAnalysisResult({
    required this.examId,
    required this.patientId,
    required this.hasLesion,
    required this.severityClass,
    required this.confidenceScore,
    required this.boundingBoxData,
    required this.showGradcam,
    required this.heatmapSaved,
    this.keyFramePath,
    this.gradcamPath,   // 저장경로
    this.gradcamUrl,    // 이미지 조회 시 주소
    this.probabilities,
    this.analysisId,
  });

  final int examId;
  final String patientId;
  final String? keyFramePath;

  final bool hasLesion;
  final String severityClass;
  final double confidenceScore;

  final AiBoundingBoxData boundingBoxData;

  final String? gradcamPath;
  final String? gradcamUrl;
  final bool showGradcam;
  final bool heatmapSaved;

  final Object? probabilities;
  final String? analysisId;

  bool get canShowBoundingBox {
    return boundingBoxData.hasDetections;
  }

  bool get canShowHeatmap {
    return heatmapSaved && gradcamUrl != null;
  }

  factory IntegratedAnalysisResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final examId = _intValue(json['exam_id']);

    if (examId == null) {
      throw const FormatException(
        '통합 분석 결과에 올바른 검사 ID가 없습니다.',
      );
    }

    final patientId = _nullableString(
      json['patient_id'],
    );

    if (patientId == null) {
      throw const FormatException(
        '통합 분석 결과에 환자 ID가 없습니다.',
      );
    }

    final boundingBoxValue =
        json['ai_bbox_data'];

    final boundingBoxData =
        boundingBoxValue is Map
            ? AiBoundingBoxData.fromJson(
                Map<String, dynamic>.from(
                  boundingBoxValue,
                ),
              )
            : const AiBoundingBoxData.empty();

    return IntegratedAnalysisResult(
      examId: examId,
      patientId: patientId,
      keyFramePath: _nullableString(
        json['key_frame_path'],
      ),
      hasLesion: _boolValue(
        json['has_lesion'],
      ),
      severityClass:
          _nullableString(
            json['severity_class'],
          ) ??
          'unknown',
      confidenceScore:
          _doubleValue(
            json['confidence_score'],
          ) ??
          0.0,
      boundingBoxData: boundingBoxData,
      gradcamPath: _nullableString(
        json['gradcam_path'],
      ),
      gradcamUrl: _nullableString(
        json['gradcam_url'],
      ),
      showGradcam: _boolValue(
        json['show_gradcam'],
      ),
      heatmapSaved: _boolValue(
        json['heatmap_saved'],
      ),
      probabilities: json['probabilities'],
      analysisId: _nullableString(
        json['analysis_id'],
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

  static double? _doubleValue(
    Object? value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return value.trim().toLowerCase() ==
          'true';
    }

    return false;
  }

  static String? _nullableString(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}

final class AiBoundingBoxData {
  const AiBoundingBoxData({
    required this.detectionCount,
    required this.detections,
    this.model,
    this.imageWidth,
    this.imageHeight,
  });

  const AiBoundingBoxData.empty()
      : model = null,
        imageWidth = null,
        imageHeight = null,
        detectionCount = 0,
        detections = const [];

  final String? model;
  final int? imageWidth;
  final int? imageHeight;
  final int detectionCount;
  final List<Map<String, dynamic>> detections;

  bool get hasDetections {
    return detectionCount > 0 &&
        detections.isNotEmpty;
  }

  factory AiBoundingBoxData.fromJson(
    Map<String, dynamic> json,
  ) {
    final detectionValues =
        json['detections'];

    final detections =
        detectionValues is List
            ? detectionValues
                .whereType<Map>()
                .map(
                  (value) =>
                      Map<String, dynamic>.from(
                    value,
                  ),
                )
                .toList()
            : <Map<String, dynamic>>[];

    return AiBoundingBoxData(
      model: _nullableString(
        json['model'],
      ),
      imageWidth: _intValue(
        json['image_width'],
      ),
      imageHeight: _intValue(
        json['image_height'],
      ),
      detectionCount:
          _intValue(
            json['detection_count'],
          ) ??
          detections.length,
      detections: detections,
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

  static String? _nullableString(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}