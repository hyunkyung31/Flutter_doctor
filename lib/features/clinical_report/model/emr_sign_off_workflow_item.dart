import '../../consultation/model/consultation_request.dart';
import 'emr_sign_off.dart';
import 'emr_sign_off_workflow_status.dart';

final class EmrSignOffWorkflowItem {
  const EmrSignOffWorkflowItem({
    required this.signOff,
    required this.status,
    this.consultation,
    this.resolvedPatientName,
  });

  final EmrSignOff signOff;
  final ConsultationRequest? consultation;
  final EmrSignOffWorkflowStatus status;
  final String? resolvedPatientName;

  String get signOffId => signOff.id;

  String get patientId => signOff.patientId;

  int? get examId => signOff.aiResult?.examId;

  String get patientName {
    final resolvedName = resolvedPatientName?.trim() ?? '';

    if (resolvedName.isNotEmpty) {
      return resolvedName;
    }

    final consultationName = consultation?.patientName.trim() ?? '';

    if (consultationName.isNotEmpty) {
      return consultationName;
    }

    return '이름 미등록';
  }

  String get finalResult => signOff.finalResult.trim();

  String get consultationReason {
    return consultation?.reason.trim() ?? '';
  }

  String get consultationResponse {
    return consultation?.responseMemo.trim() ?? '';
  }

  bool get hasConsultation => consultation != null;

  bool get hasConsultationResponse {
    return consultationResponse.isNotEmpty;
  }

  DateTime? get updatedAt {
    final signOffDate = signOff.updatedAt ?? signOff.createdAt;
    final consultationDate =
        consultation?.completedAt ?? consultation?.createdAt;

    if (signOffDate == null) {
      return consultationDate;
    }

    if (consultationDate == null) {
      return signOffDate;
    }

    return consultationDate.isAfter(signOffDate)
        ? consultationDate
        : signOffDate;
  }

  factory EmrSignOffWorkflowItem.fromSignOff({
    required EmrSignOff signOff,
    required List<ConsultationRequest> sentConsultations,
    String? patientName,
  }) {
    final consultation = _findLatestConsultation(
      signOff: signOff,
      sentConsultations: sentConsultations,
    );

    return EmrSignOffWorkflowItem(
      signOff: signOff,
      consultation: consultation,
      resolvedPatientName: patientName,
      status: _resolveStatus(signOff: signOff, consultation: consultation),
    );
  }

  static ConsultationRequest? _findLatestConsultation({
    required EmrSignOff signOff,
    required List<ConsultationRequest> sentConsultations,
  }) {
    final examId = signOff.aiResult?.examId;

    if (examId == null) {
      return null;
    }

    final matches = sentConsultations.where((consultation) {
      return consultation.patientId.trim() == signOff.patientId.trim() &&
          consultation.examId == examId;
    }).toList();

    if (matches.isEmpty) {
      return null;
    }

    matches.sort((first, second) {
      final firstDate = first.createdAt;
      final secondDate = second.createdAt;

      if (firstDate == null && secondDate == null) {
        return 0;
      }

      if (firstDate == null) {
        return 1;
      }

      if (secondDate == null) {
        return -1;
      }

      return secondDate.compareTo(firstDate);
    });

    return matches.first;
  }

  static EmrSignOffWorkflowStatus _resolveStatus({
    required EmrSignOff signOff,
    required ConsultationRequest? consultation,
  }) {
    if (signOff.emrTransmitted) {
      return EmrSignOffWorkflowStatus.transmitted;
    }

    if (signOff.reportReady) {
      return EmrSignOffWorkflowStatus.reportReady;
    }

    if (signOff.finalized) {
      return EmrSignOffWorkflowStatus.finalized;
    }

    if (consultation == null) {
      return EmrSignOffWorkflowStatus.draft;
    }

    final consultationStatus = consultation.status.trim().toLowerCase();

    if (consultation.responseMemo.trim().isNotEmpty ||
        consultationStatus == 'completed') {
      return EmrSignOffWorkflowStatus.consultationAnswered;
    }

    if (consultation.isPending ||
        consultationStatus == 'accepted' ||
        consultationStatus == 'in_progress') {
      return EmrSignOffWorkflowStatus.consultationPending;
    }

    return EmrSignOffWorkflowStatus.draft;
  }
}
