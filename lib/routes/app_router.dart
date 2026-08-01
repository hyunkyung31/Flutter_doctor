import 'package:go_router/go_router.dart';
import '../features/auth/view/login_screen.dart';
import 'route_names.dart';
import '../features/home/home_routes.dart';
import '../features/patient/view/patient_list_view.dart';
import '../features/splash/view/splash_screen.dart';

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

      GoRoute(
        path: '/patient',
        builder: (context, state) {
          return const PatientListView();
        },
      ),
      GoRoute( // 로그인 화면
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      )
    ],
  );
}