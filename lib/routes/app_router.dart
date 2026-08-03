import 'package:go_router/go_router.dart';

import '../features/auth/view/login_screen.dart';
import '../features/home/home_routes.dart';
import '../features/patient/patient_routes.dart';
import '../features/splash/view/splash_screen.dart';
import '../features/calendar/calendar_routes.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splashPath,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      ...homeRoutes,

      ...patientRoutes,

      ...calendarRoutes,

      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
    ],
  );
}