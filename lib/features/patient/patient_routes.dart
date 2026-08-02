import 'package:doctor_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'repository/patient_repository.dart';
import 'view/patient_detail_view.dart';
import 'view/patient_list_view.dart';
import 'view_model/patient_detail_view_model.dart';

final List<RouteBase> patientRoutes = [
  GoRoute(
    path: '/patient',
    name: 'patientList',
    builder: (
      context,
      state,
    ) {
      return const PatientListView();
    },
  ),
  GoRoute(
    path: '/patient/detail/:patientId',
    name: 'patientDetail',
    builder: (
      context,
      state,
    ) {
      final patientId =
          state.pathParameters['patientId'];

      if (patientId == null ||
          patientId.trim().isEmpty) {
        return const _PatientNotFoundView();
      }

      return ChangeNotifierProvider<
          PatientDetailViewModel>(
        create: (context) {
          return PatientDetailViewModel(
            patientRepository:
                context.read<
                    PatientRepository>(),
            secureStorage:
                context.read<
                    SecureStorage>(),
          );
        },
        child: PatientDetailView(
          patientId: patientId,
        ),
      );
    },
  ),
];

final class _PatientNotFoundView
    extends StatelessWidget {
  const _PatientNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '환자 상세 정보',
        ),
      ),
      body: const Center(
        child: Text(
          '환자 ID가 올바르지 않습니다.',
        ),
      ),
    );
  }
}