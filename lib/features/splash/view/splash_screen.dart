import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vena_logo.dart';
import '../../../routes/route_names.dart';
import '../../auth/view_model/auth_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasHandledCompletion = false;

  Future<void> _handleLogoCompleted() async {
    if (_hasHandledCompletion) {
      return;
    }

    _hasHandledCompletion = true;

    final authViewModel = context.read<AuthViewModel>();

    final isRestored = await authViewModel.authenticateAndRestoreSession();

    if (!mounted) {
      return;
    }

    if (isRestored) {
      context.go('/home');
      return;
    }

    context.go(RouteNames.loginPath);}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: VenaLogo(
            onCompleted: _handleLogoCompleted,
          ),
        ),
      ),
    );
  }
}