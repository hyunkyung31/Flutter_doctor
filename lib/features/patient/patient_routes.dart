import 'package:doctor_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'repository/patient_repository.dart';
import 'view/patient_detail_view.dart';
import 'view/patient_list_view.dart';
import 'view_model/patient_detail_view_model.dart';
import '../auth/view/sensitive_access_gate.dart'; // 추가 - 민감정보 재인증
import '../../core/security/screen_protection/screen_capture_guard.dart'; // 추가 - 캡처방지

final List<RouteBase> patientRoutes = [
  GoRoute(
    path: '/patient',
    name: 'patientList',
    builder: (context, state) {
      return const PatientListView();
    },
  ),
  GoRoute(
    path: '/patient/detail/:patientId',
    name: 'patientDetail',
    builder: (context, state) {
      final patientId = state.pathParameters['patientId'];

      if (patientId == null || patientId.trim().isEmpty) {
        return const _PatientNotFoundView();
      }
      // 수정 - 민감정보 재인증, 캡처 방지 추가
      return ChangeNotifierProvider<PatientDetailViewModel>(
        create: (context) {
          return PatientDetailViewModel(
            patientRepository: context.read<PatientRepository>(),
            secureStorage: context.read<SecureStorage>(),
          );
        },
        child: SensitiveAccessGate(
          localizedReason: "환자 상세정보와 의료영상을 확인하려면 본인 인증이 필요합니다.",
          child: ScreenCaptureGuard(
            child: PatientDetailView(patientId: patientId),
          ),
        ),
      );
    },
  ),
];

final class _PatientNotFoundView extends StatelessWidget {
  const _PatientNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('환자 상세 정보')),
      body: const Center(child: Text('환자 ID가 올바르지 않습니다.')),
    );
  }
}
