import 'package:go_router/go_router.dart';
import '../features/auth/view/login_screen.dart';
import 'route_names.dart';
import '../features/home/home_routes.dart';
import '../features/patient/view/patient_list_view.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',  //  - splash화면 연결 전까지 main 초기 경로 이걸로 유지
    routes: [
      // GoRoute(
      //   path: '/',
      //   builder: (context, state) {
      //     return const Scaffold(
      //       body: Center([]
      //         child: Text('화면 연결 전'),
      //       ),
      //     );
      //   },
      // ),

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