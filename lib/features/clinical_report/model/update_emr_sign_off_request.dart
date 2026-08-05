final class UpdateEmrSignOffRequest {
  const UpdateEmrSignOffRequest({
    this.patientId,
    this.finalized,
    this.finalResult,
    this.aiResult,
    this.emrTransmitted,
    this.reportReady,
  });

  final String? patientId;
  final bool? finalized;
  final String? finalResult;
  final String? aiResult;
  final bool? emrTransmitted;
  final bool? reportReady;

  bool get isEmpty {
    return patientId == null &&
        finalized == null &&
        finalResult == null &&
        aiResult == null &&
        emrTransmitted == null &&
        reportReady == null;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (patientId != null) {
      json['patient_id'] = patientId!.trim();
    }

    if (finalized != null) {
      json['finalized'] = finalized;
    }

    if (finalResult != null) {
      json['final_result'] = finalResult!.trim();
    }

    if (aiResult != null) {
      json['ai_result'] = aiResult!.trim();
    }

    if (emrTransmitted != null) {
      json['emr_transmitted'] = emrTransmitted;
    }

    if (reportReady != null) {
      json['report_ready'] = reportReady;
    }

    return json;
  }
}
