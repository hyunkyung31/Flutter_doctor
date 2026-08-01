import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vena_logo.dart';
import '../../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  void _moveToLogin() {
    if (_isNavigating || !mounted) {
      return;
    }

    _isNavigating = true;
    context.go(RouteNames.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: VenaLogo(
            onCompleted: _moveToLogin,
          ),
        ),
      ),
    );
  }
}