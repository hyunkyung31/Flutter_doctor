import 'package:go_router/go_router.dart';

import 'view/appointment_list_view.dart';

final List<RouteBase> appointmentRoutes = [
  GoRoute(
    path: '/appointments',
    name: 'appointmentList',
    builder: (context, state) {
      return const AppointmentListView();
    },
  ),
];
