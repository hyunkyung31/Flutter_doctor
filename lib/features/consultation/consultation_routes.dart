import 'package:go_router/go_router.dart';

import 'view/consultation_request_view.dart';

final List<RouteBase>
    consultationRoutes = [
  GoRoute(
    path: '/consultation/request',
    name: 'consultationRequest',
    builder: (
      context,
      state,
    ) {
      return const ConsultationRequestView();
    },
  ),
];