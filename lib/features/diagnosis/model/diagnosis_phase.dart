// 환자 상세 api의 검사 map 데이터를 분석 화면에서 쓰기 쉬운 형태로 변환

enum DiagnosisPhase {
  idle, // 분석화면 들어온 상태
  selecting, //환자, 검사, 분석 방식 선택중
  ready, // 분석실행에 필요한 값이 모두 선택된 상태
  submitting, // Django에 분석 요청중
  analyzing, // Django에서 분석중
  completed, // 분석 완료
  failed, // 분석 실패
}

extension DiagnosisPhaseState on DiagnosisPhase {
  bool get isBusy {
    return this == DiagnosisPhase.submitting ||
        this == DiagnosisPhase.analyzing;
  }

  bool get hasCompletedAnalysis {
    return this == DiagnosisPhase.completed;
  }

  bool get canChangeSelection {
    return this == DiagnosisPhase.idle ||
        this == DiagnosisPhase.selecting ||
        this == DiagnosisPhase.ready ||
        this == DiagnosisPhase.failed;
  }
}
