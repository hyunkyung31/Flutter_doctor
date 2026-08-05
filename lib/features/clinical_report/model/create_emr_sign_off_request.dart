final class CreateEmrSignOffRequest {
  const CreateEmrSignOffRequest({
    required this.patientId,
    required this.finalResult,
    required this.aiResult,
    this.finalized = false,
    this.emrTransmitted = false,
    this.reportReady = false,
  });

  final String patientId;
  final bool finalized;
  final String finalResult;
  final String aiResult;
  final bool emrTransmitted;
  final bool reportReady;

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId.trim(),
      'finalized': finalized,
      'final_result': finalResult.trim(),
      'ai_result': aiResult.trim(),
      'emr_transmitted': emrTransmitted,
      'report_ready': reportReady,
    };
  }
}
