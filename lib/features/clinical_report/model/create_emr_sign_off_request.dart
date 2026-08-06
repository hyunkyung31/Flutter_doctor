final class CreateEmrSignOffRequest {
  const CreateEmrSignOffRequest({
    required this.patientId,
    required this.examId,
    required this.finalResult,
    this.finalized = false,
  });

  final String patientId;

  // Django가 해당 검사의 AI 결과를 조회하고 스냅샷하기 위해 사용하는 검사 ID
  final int examId;

  // 의료진이 작성한 최종 소견이며, 초안 단계에서는 빈 문자열일 수 있음
  final String finalResult;

  // false이면 초안이고, true이면 최종 승인 상태
  final bool finalized;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patient_id': patientId.trim(),
      'exam_id': examId,
      'final_result': finalResult.trim(),
      'finalized': finalized,
    };
  }
}
