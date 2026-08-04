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
        detections = const <AiDetection>[];

  // 탐지에 사용된 모델명
  final String? model;

  // YOLO 추론에 사용된 원본 이미지 너비
  final int? imageWidth;

  // YOLO 추론에 사용된 원본 이미지 높이
  final int? imageHeight;

  // 서버가 반환한 전체 BBox 개수
  final int detectionCount;

  // 파싱에 성공한 개별 YOLO 탐지 결과
  final List<AiDetection> detections;

  // 실제로 화면에 그릴 수 있는 BBox가 하나 이상 존재하는지 확인한다.
  bool get hasDetections {
    return detections.any(
      (detection) => detection.hasDrawableBox,
    );
  }

  // 탐지된 BBox 중 가장 높은 YOLO confidence를 반환한다.
  //
  // InceptionV3의 confidenceScore와는 다른 값이며,
  // 표시 가능한 confidence가 없다면 null을 반환한다.
  double? get highestDetectionConfidence {
    double? highestConfidence;

    for (final detection in detections) {
      final confidence = detection.confidence;

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
    final parsedDetections =
        <AiDetection>[];

    final detectionValues =
        json['detections'];

    if (detectionValues is List) {
      for (final value in detectionValues) {
        if (value is! Map) {
          continue;
        }

        final detection =
            AiDetection.tryParse(
          Map<String, dynamic>.from(value),
        );

        if (detection != null) {
          parsedDetections.add(detection);
        }
      }
    }

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
          List<AiDetection>.unmodifiable(
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

// YOLO가 반환한 개별 병변 탐지 결과
final class AiDetection {
  const AiDetection({
    required this.box,
    required this.normalizedBox,
    this.detectionId,
    this.detectionIndex,
    this.source,
    this.editStatus,
    this.classId,
    this.className,
    this.confidence,
  });

  // 서버가 생성한 개별 탐지 식별자
  final String? detectionId;

  // 전체 탐지 목록에서의 순서
  final int? detectionIndex;

  // 탐지 데이터 생성 주체
  final String? source;

  // 원본 또는 수정 상태
  final String? editStatus;

  // YOLO 클래스 ID
  final int? classId;

  // YOLO 클래스 이름
  final String? className;

  // YOLO 개별 BBox 탐지 신뢰도
  final double? confidence;

  // 원본 이미지 픽셀 기준 좌표
  final AiBoundingBox? box;

  // 0부터 1까지의 정규화 좌표
  final AiBoundingBox? normalizedBox;

  // 정규화 또는 픽셀 BBox가 존재하는지 확인한다.
  bool get hasDrawableBox {
    return normalizedBox != null ||
        box != null;
  }

  // 서버 응답 하나를 안전하게 파싱한다.
  //
  // box와 box_normalized가 모두 잘못된 경우에는 화면에 그릴 수
  // 없으므로 null을 반환하고 해당 탐지를 전체 목록에서 제외한다.
  static AiDetection? tryParse(
    Map<String, dynamic> json,
  ) {
    final boxValue = json['box'];

    final normalizedBoxValue =
        json['box_normalized'];

    final box = boxValue is Map
        ? AiBoundingBox.tryParse(
            Map<String, dynamic>.from(
              boxValue,
            ),
          )
        : null;

    final normalizedBox =
        normalizedBoxValue is Map
            ? AiBoundingBox.tryParse(
                Map<String, dynamic>.from(
                  normalizedBoxValue,
                ),
              )
            : null;

    if (box == null &&
        normalizedBox == null) {
      return null;
    }

    final confidence = _doubleValue(
      json['confidence'],
    );

    return AiDetection(
      detectionId: _nullableString(
        json['detection_id'],
      ),
      detectionIndex: _intValue(
        json['detection_index'],
      ),
      source: _nullableString(
        json['source'],
      ),
      editStatus: _nullableString(
        json['edit_status'],
      ),
      classId: _intValue(
        json['class_id'],
      ),
      className: _nullableString(
        json['class_name'],
      ),
      confidence:
          confidence != null &&
                  confidence.isFinite
              ? confidence
              : null,
      box: box,
      normalizedBox: normalizedBox,
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

// 하나의 직사각형 BBox 좌표를 표현한다.
final class AiBoundingBox {
  const AiBoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.width,
    required this.height,
  });

  // 왼쪽 위 X 좌표
  final double x1;

  // 왼쪽 위 Y 좌표
  final double y1;

  // 오른쪽 아래 X 좌표
  final double x2;

  // 오른쪽 아래 Y 좌표
  final double y2;

  // BBox 너비
  final double width;

  // BBox 높이
  final double height;

  // 좌표가 올바른 직사각형을 구성하는지 확인한다.
  bool get isValid {
    return x1.isFinite &&
        y1.isFinite &&
        x2.isFinite &&
        y2.isFinite &&
        width.isFinite &&
        height.isFinite &&
        x2 > x1 &&
        y2 > y1 &&
        width > 0 &&
        height > 0;
  }

  // 좌표가 0부터 1 사이의 정규화 범위에 있는지 확인한다.
  bool get isNormalized {
    return isValid &&
        x1 >= 0 &&
        y1 >= 0 &&
        x2 <= 1 &&
        y2 <= 1;
  }

  static AiBoundingBox? tryParse(
    Map<String, dynamic> json,
  ) {
    final x1 = _doubleValue(
      json['x1'],
    );

    final y1 = _doubleValue(
      json['y1'],
    );

    final x2 = _doubleValue(
      json['x2'],
    );

    final y2 = _doubleValue(
      json['y2'],
    );

    if (x1 == null ||
        y1 == null ||
        x2 == null ||
        y2 == null ||
        !x1.isFinite ||
        !y1.isFinite ||
        !x2.isFinite ||
        !y2.isFinite ||
        x2 <= x1 ||
        y2 <= y1) {
      return null;
    }

    final calculatedWidth =
        x2 - x1;

    final calculatedHeight =
        y2 - y1;

    final responseWidth =
        _doubleValue(
      json['width'],
    );

    final responseHeight =
        _doubleValue(
      json['height'],
    );

    final width =
        responseWidth != null &&
                responseWidth.isFinite &&
                responseWidth > 0
            ? responseWidth
            : calculatedWidth;

    final height =
        responseHeight != null &&
                responseHeight.isFinite &&
                responseHeight > 0
            ? responseHeight
            : calculatedHeight;

    final boundingBox =
        AiBoundingBox(
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      width: width,
      height: height,
    );

    return boundingBox.isValid
        ? boundingBox
        : null;
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
}