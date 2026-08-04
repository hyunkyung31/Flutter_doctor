import 'package:go_router/go_router.dart';

import '../patient/model/patient.dart';
import 'view/consultation_form_view.dart';
import 'view/consultation_request_view.dart';

final List<RouteBase> consultationRoutes = [
  GoRoute(
    path: '/consultation/request',
    name: 'consultationRequest',
    builder: (context, state) {
      return const ConsultationRequestView();
    },
  ),
  GoRoute(
    path: '/consultation/form',
    name: 'consultationForm',
    builder: (context, state) {
      final patient = state.extra as Patient;

      return ConsultationFormView(patient: patient);
    },
  ),
];
