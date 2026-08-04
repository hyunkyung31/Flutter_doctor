// 통합 AI 분석 API의 전체 응답을 표현
// 서버에서는 YOLO 병변 탐지, InceptionV3 분류와 Grad-CAM 결과를 하나의 응답으로 반환
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
    this.gradcamPath,
    this.gradcamUrl,
    this.probabilities,
    this.analysisId,
  });

  // 분석 대상 검사 ID
  final int examId;

  // 분석 대상 환자 ID
  final String patientId;

  // 서버에 저장된 원본 키프레임 경로
  final String? keyFramePath;

  // 서버의 통합 판정 기준상 병변 존재 여부
  final bool hasLesion;

  // 서버가 반환한 정상·협착 판정값
  final String severityClass;

  // InceptionV3 분류 신뢰도
  final double confidenceScore;

  // YOLO 병변 탐지 결과
  final AiBoundingBoxData boundingBoxData;

  // 서버에 저장된 Grad-CAM 이미지 경로
  final String? gradcamPath;

  // Flutter에서 Grad-CAM 이미지를 조회할 때 사용하는 URL
  final String? gradcamUrl;

  // 서버가 Grad-CAM 표시를 요청했는지
  final bool showGradcam;

  // Grad-CAM 이미지가 정상적으로 저장됐는지
  final bool heatmapSaved;

  // 서버에서 반환한 클래스별 분류 확률 원본값
  final Object? probabilities;

  // 서버가 분석 식별자를 제공하는 경우 저장
  final String? analysisId;

  // YOLO가 표시 가능한 병변 영역을 반환했는지 확인
  bool get canShowBoundingBox {
    return boundingBoxData.hasDetections;
  }

  // Grad-CAM 이미지가 저장됐고 조회 URL도 있는지 확인
  bool get canShowHeatmap {
    return heatmapSaved && gradcamUrl != null;
  }

  factory IntegratedAnalysisResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final examId = _intValue(
      json['exam_id'],
    );

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

  static int? _intValue(
    Object? value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
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
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  static bool _boolValue(
    Object? value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalizedValue =
          value.trim().toLowerCase();

      return normalizedValue == 'true' ||
          normalizedValue == '1';
    }

    return false;
  }

  static String? _nullableString(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    return text.isEmpty ? null : text;
  }
}

// YOLO가 반환한 전체 BBox 탐지 결과
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
        detections =
            const <Map<String, dynamic>>[];

  // 탐지에 사용된 모델명
  final String? model;

  // YOLO 추론에 사용된 이미지 너비
  final int? imageWidth;

  // YOLO 추론에 사용된 이미지 높이
  final int? imageHeight;

  // 서버가 반환한 전체 BBox 개수
  final int detectionCount;

  // 개별 BBox 좌표, 클래스와 confidence를 포함한 원본 목록
  final List<Map<String, dynamic>> detections;

  // 표시할 수 있는 BBox가 하나 이상 존재하는지 확인
  bool get hasDetections {
    return detectionCount > 0 &&
        detections.isNotEmpty;
  }

  // 탐지된 BBox 중 가장 높은 YOLO confidence를 반환
  // 탐지 결과가 없거나 유효한 confidence 값이 없다면0%로 오해하지 않도록 null을 반환
  double? get highestDetectionConfidence {
    double? highestConfidence;

    for (final detection in detections) {
      final confidence = _doubleValue(
        detection['confidence'],
      );

      if (confidence == null ||
          !confidence.isFinite) {
        continue;
      }

      if (highestConfidence == null ||
          confidence > highestConfidence) {
        highestConfidence = confidence;
      }
    }

    return highestConfidence;
  }

  factory AiBoundingBoxData.fromJson(
    Map<String, dynamic> json,
  ) {
    final detectionValues =
        json['detections'];

    final parsedDetections =
        detectionValues is List
            ? detectionValues
                .whereType<Map>()
                .map(
                  (value) =>
                      Map<String, dynamic>.from(
                    value,
                  ),
                )
                .toList(
                  growable: false,
                )
            : <Map<String, dynamic>>[];

    final detectionCount =
        _intValue(
          json['detection_count'],
        ) ??
        parsedDetections.length;

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
      detectionCount: detectionCount,
      detections:
          List<Map<String, dynamic>>
              .unmodifiable(
        parsedDetections,
      ),
    );
  }

  static int? _intValue(
    Object? value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
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
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  static String? _nullableString(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    return text.isEmpty ? null : text;
  }
}