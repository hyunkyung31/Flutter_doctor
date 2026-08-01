import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/patient/view/patient_list_view.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/patient',
    routes: [
      // GoRoute(
      //   path: '/',
      //   builder: (context, state) {
      //     return const Scaffold(
      //       body: Center(
      //         child: Text('화면 연결 전'),
      //       ),
      //     );
      //   },
      // ),

      GoRoute(
        path: '/patient',
        builder: (context, state) {
          return const PatientListView();
        },
      ),
    ],
  );
}