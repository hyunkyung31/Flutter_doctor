// 탐지, 분류, 통합 분석의 종류와 화면 표시 정보 관리

enum AiAnalysisType {
  detection, // YOLOv11 탐지
  classification, // InceptionV3 분류
  integrated, // YOLOv11 탐지 + InceptionV3 분류 + Grad-CAM 설명
}

extension AiAnalysisTypePresentation on AiAnalysisType {
  String get title {
    switch (this) {
      case AiAnalysisType.detection:
        return '병변 탐지 결과 보기';

      case AiAnalysisType.classification:
        return '정상·협착 분류 결과 보기';

      case AiAnalysisType.integrated:
        return '통합 분석 결과 보기';
    }
  }

  String get description {
    switch (this) {
      case AiAnalysisType.detection:
        return 'YOLOv11이 탐지한 협착 의심 영역과 신뢰도를 확인합니다.';

      case AiAnalysisType.classification:
        return 'InceptionV3의 정상 또는 협착 가능성 분류와 Grad-CAM 설명을 확인합니다.';

      case AiAnalysisType.integrated:
        return 'YOLOv11 BBox와 InceptionV3 분류 및 Grad-CAM 설명 결과를 함께 확인합니다.';
    }
  }


  bool get supportsBoundingBox {
    return this == AiAnalysisType.detection ||
        this == AiAnalysisType.integrated;
  }

  bool get supportsHeatmap {
    return this == AiAnalysisType.classification ||
        this == AiAnalysisType.integrated;
  }
}