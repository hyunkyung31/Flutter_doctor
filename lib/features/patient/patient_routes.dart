import 'package:go_router/go_router.dart';

import 'view/patient_list_view.dart';

final List<RouteBase> patientRoutes = [
  GoRoute(
    path: '/patient',
    name: 'patientList',
    builder: (context, state) {
      return const PatientListView();
    },
  ),
];