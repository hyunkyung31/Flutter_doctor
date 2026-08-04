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
        return '병변 탐지';

      case AiAnalysisType.classification:
        return '정상·협착 분류';

      case AiAnalysisType.integrated:
        return '통합 분석';
    }
  }

  String get description {
    switch (this) {
      case AiAnalysisType.detection:
        return 'YOLOv11을 이용해 협착 의심 영역과 신뢰도를 탐지합니다.';

      case AiAnalysisType.classification:
        return 'InceptionV3를 이용해 정상 또는 협착 가능성을 분류합니다.';

      case AiAnalysisType.integrated:
        return 'YOLOv11 탐지, InceptionV3 분류와 Grad-CAM 설명 결과를 함께 생성합니다.';
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