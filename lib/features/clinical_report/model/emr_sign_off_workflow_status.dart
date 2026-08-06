enum EmrSignOffWorkflowStatus {
  draft,
  consultationPending,
  consultationAnswered,
  finalized,
  reportReady,
  transmitted,
}

extension EmrSignOffWorkflowStatusX on EmrSignOffWorkflowStatus {
  String get label {
    switch (this) {
      case EmrSignOffWorkflowStatus.draft:
        return '작성 중';

      case EmrSignOffWorkflowStatus.consultationPending:
        return '협진 대기';

      case EmrSignOffWorkflowStatus.consultationAnswered:
        return '답변 도착';

      case EmrSignOffWorkflowStatus.finalized:
        return 'SIGN OFF 완료';

      case EmrSignOffWorkflowStatus.reportReady:
        return 'PDF 생성 완료';

      case EmrSignOffWorkflowStatus.transmitted:
        return '전달 완료';
    }
  }

  String get description {
    switch (this) {
      case EmrSignOffWorkflowStatus.draft:
        return '의료진 소견 초안을 작성하거나 수정할 수 있습니다.';

      case EmrSignOffWorkflowStatus.consultationPending:
        return '협진 의료진의 답변을 기다리고 있습니다.';

      case EmrSignOffWorkflowStatus.consultationAnswered:
        return '협진 답변을 참고하여 최종 소견을 작성할 수 있습니다.';

      case EmrSignOffWorkflowStatus.finalized:
        return '최종 소견 승인이 완료되어 수정할 수 없습니다.';

      case EmrSignOffWorkflowStatus.reportReady:
        return '임상 보고서 PDF 생성이 완료되었습니다.';

      case EmrSignOffWorkflowStatus.transmitted:
        return '임상 보고서 전달 처리가 완료되었습니다.';
    }
  }

  bool get allowsEditing {
    return this == EmrSignOffWorkflowStatus.draft ||
        this == EmrSignOffWorkflowStatus.consultationAnswered;
  }

  bool get isWaitingForConsultation {
    return this == EmrSignOffWorkflowStatus.consultationPending;
  }

  bool get isFinalized {
    return this == EmrSignOffWorkflowStatus.finalized ||
        this == EmrSignOffWorkflowStatus.reportReady ||
        this == EmrSignOffWorkflowStatus.transmitted;
  }
}
