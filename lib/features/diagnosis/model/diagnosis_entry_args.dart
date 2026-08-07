// 홈 또는 환자 상세에서 분석화면으로 들어올 때 전달되는 값 관리

final class DiagnosisEntryArgs {
  const DiagnosisEntryArgs({this.patientId, this.examId});

  final String? patientId; // 홈화면에서 바로 AI분석화면으로 이동하면 환자 선택 안 한 상태라 null일 수 있음
  final int? examId;

  String? get normalizedPatientId {
    final value = patientId?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool get hasPatient {
    // 환자 상세에서 진입, 환자가 선택되어있는 상태인지 확인
    return normalizedPatientId != null;
  }

  bool get hasExamination {
    //검사가 이미 전달되어있는지 확인
    return examId != null;
  }
}
