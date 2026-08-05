final class UpdateEmrSignOffRequest {
  const UpdateEmrSignOffRequest({
    this.examId,
    this.finalized,
    this.finalResult,
  });

  // 연결할 검사를 변경해야 할 때만 전달
  final int? examId;

  // false는 초안 저장, true는 최종 승인을 의미
  final bool? finalized;

  // 수정할 의료진 소견
  final String? finalResult;

  bool get isEmpty {
    return examId == null && finalized == null && finalResult == null;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (examId != null) {
      json['exam_id'] = examId;
    }

    if (finalized != null) {
      json['finalized'] = finalized;
    }

    if (finalResult != null) {
      json['final_result'] = finalResult!.trim();
    }

    return json;
  }
}
