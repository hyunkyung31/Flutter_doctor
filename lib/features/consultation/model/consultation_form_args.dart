import '../../patient/model/patient.dart';

final class ConsultationFormArgs {
  const ConsultationFormArgs({
    required this.patient,
    this.examId,
    this.initialMemo = '',
  });

  final Patient patient;
  final int? examId;
  final String initialMemo;
}
