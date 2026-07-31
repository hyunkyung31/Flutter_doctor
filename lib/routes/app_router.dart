import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view/login_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',  // RouteNames.splashPath 경로 상수로 변경 가능 !! - splash화면 연결, 변경 시 공유할 것
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: Text('화면 연결 전'),
            ),
          );
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
