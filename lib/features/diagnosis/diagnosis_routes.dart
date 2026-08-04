import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../patient/repository/patient_repository.dart';
import 'model/diagnosis_entry_args.dart';
import 'repository/diagnosis_repository.dart';
import 'view/diagnosis_view.dart';
import 'view_model/diagnosis_view_model.dart';
import '../../core/storage/secure_storage.dart';

// AI 분석 요청 화면의 Route 이름과 경로를 기능 내부에서 관리
abstract final class DiagnosisRoute {
  static const String name = 'diagnosis';
  static const String path = '/diagnosis';
}

// AI 분석 요청 기능에서 사용하는 Route 목록
final List<RouteBase> diagnosisRoutes = [
  GoRoute(
    path: DiagnosisRoute.path,
    name: DiagnosisRoute.name,
    builder: (
      context,
      state,
    ) {
      // 홈 진입은 기본 인자를 사용, 환자 상세 진입은 state.extra로 전달된 patientId와 examId를 사용
      final entryArgs =
          _resolveEntryArgs(state);

      // 분석 상태는 환자와 검사마다 달라지므로 화면 진입마다 새로 생성
      return ChangeNotifierProvider<
          DiagnosisViewModel>(
        create: (context) =>
            DiagnosisViewModel(
          context.read<
              DiagnosisRepository>(),
          context.read<
              PatientRepository>(),
          secureStorage: context.read<SecureStorage>(),
          entryArgs: entryArgs,
        ),
        child: const DiagnosisView(),
      );
    },
  ),
];

// 앱 내부 이동에서는 state.extra를 우선 사용, 직접 경로 접근을 고려해 Query Parameter도 보조적으로 처리한다.
DiagnosisEntryArgs _resolveEntryArgs(
  GoRouterState state,
) {
  final extra = state.extra;

  if (extra is DiagnosisEntryArgs) {
    return extra;
  }

  final patientId =
      state.uri.queryParameters[
          'patientId'];

  final examIdText =
      state.uri.queryParameters[
          'examId'];

  return DiagnosisEntryArgs(
    patientId: patientId,
    examId: examIdText == null
        ? null
        : int.tryParse(
            examIdText.trim(),
          ),
  );
}