import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/storage/secure_storage.dart';
import '../patient/model/patient.dart';
import '../patient/repository/patient_repository.dart';
import '../patient/view_model/patient_detail_view_model.dart';
import 'model/consultation_request.dart';
import 'model/consultation_form_args.dart';
import 'view/consultation_detail_view.dart';
import 'view/consultation_form_view.dart';
import 'view/consultation_inbox_view.dart';
import 'view/consultation_request_view.dart';

final List<RouteBase> consultationRoutes = [
  GoRoute(
    path: '/consultation/inbox',
    name: 'consultationInbox',
    builder: (context, state) {
      return const ConsultationInboxView();
    },
  ),
  GoRoute(
    path: '/consultation/request',
    name: 'consultationRequest',
    builder: (context, state) {
      return const ConsultationRequestView();
    },
  ),
  GoRoute(
    path: '/consultation/detail',
    name: 'consultationDetail',
    builder: (context, state) {
      final request = state.extra;

      if (request is! ConsultationRequest) {
        return const Scaffold(body: Center(child: Text('협진 요청 정보가 없습니다.')));
      }

      return ChangeNotifierProvider<PatientDetailViewModel>(
        create: (context) => PatientDetailViewModel(
          patientRepository: context.read<PatientRepository>(),
          secureStorage: context.read<SecureStorage>(),
        ),
        child: ConsultationDetailView(request: request),
      );
    },
  ),
  GoRoute(
    path: '/consultation/form',
    name: 'consultationForm',
    builder: (context, state) {
      final extra = state.extra;

      if (extra is ConsultationFormArgs) {
        return ConsultationFormView(
          patient: extra.patient,
          examId: extra.examId,
          initialMemo: extra.initialMemo,
        );
      }

      if (extra is Patient) {
        return ConsultationFormView(patient: extra);
      }

      return const Scaffold(
        body: Center(child: Text('협진 요청에 필요한 환자 정보가 없습니다.')),
      );
    },
  ),
];
