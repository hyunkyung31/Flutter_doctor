import 'package:doctor_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_model/auth_view_model.dart';


// 의료진 로그인 화면
final class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 입력값을 검사한 후 AuthViewModel에 로그인 요청
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    // 로그인 요청과 보안 저장소 토큰 저장을 기존 구조 그대로 사용
    final isSuccess = await authViewModel.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    // 비동기 로그인 처리 중 화면이 제거됐는지 확인
    if (!mounted) {
      return;
    }

    if (isSuccess) {
      context.go('/home');
    }
  }

  // 비밀번호 표시 여부 전환
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '아이디를 입력해 주세요.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.secondary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    24 + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 22 : 30,
                                    vertical: isCompact ? 26 : 34,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppColors.lightBlue,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x141E3A8A),
                                        blurRadius: 28,
                                        offset: Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const _LoginHeader(),
                                      const SizedBox(height: 30),
                                      TextFormField(
                                        controller: _usernameController,
                                        enabled: !authViewModel.isLoading,
                                        autofillHints: const [
                                          AutofillHints.username,
                                        ],
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        decoration: _inputDecoration(
                                          label: '아이디',
                                          hint: '의료진 아이디를 입력해 주세요.',
                                          prefixIcon: Icons.person_outline,
                                        ),
                                        validator: _validateUsername,
                                        onChanged: (_) {
                                          authViewModel.clearError();
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        enabled: !authViewModel.isLoading,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        decoration: _inputDecoration(
                                          label: '비밀번호',
                                          hint: '비밀번호를 입력해 주세요.',
                                          prefixIcon: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            onPressed: authViewModel.isLoading
                                                ? null
                                                : _togglePasswordVisibility,
                                            tooltip: _obscurePassword
                                                ? '비밀번호 표시'
                                                : '비밀번호 숨기기',
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        validator: _validatePassword,
                                        onChanged: (_) {
                                          authViewModel.clearError();
                                        },
                                        onFieldSubmitted: (_) async {
                                          if (!authViewModel.isLoading) {
                                            await _submit();
                                          }
                                        },
                                      ),
                                      if (authViewModel.errorMessage != null) ...[
                                        const SizedBox(height: 16),
                                        _LoginMessage(
                                          message:
                                              authViewModel.errorMessage!,
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        height: 56,
                                        child: FilledButton(
                                          onPressed: authViewModel.isLoading
                                              ? null
                                              : _submit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            disabledBackgroundColor:
                                                AppColors.primary.withAlpha(166),
                                            foregroundColor: AppColors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: authViewModel.isLoading
                                                ? const Row(
                                                    key: ValueKey('loading'),
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.2,
                                                          color: AppColors.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text('로그인 중...'),
                                                    ],
                                                  )
                                                : const Text(
                                                    '로그인',
                                                    key: ValueKey('login'),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const _SecurityNotice(),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 로그인 화면의 VENA 브랜드 영역
final class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/vena_login_logo.png',
          height: 88,
          fit: BoxFit.contain,
          semanticLabel: 'VENA',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                '의료진 전용',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'VENA - MD',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '등록된 의료진 계정으로\nVENA 의료진 전용 서비스를 이용할 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// 로그인 실패 메시지
final class _LoginMessage extends StatelessWidget {
  const _LoginMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 15,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '로그인 정보는 기기의 보안 저장소에\n'
              '안전하게 보관됩니다.',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// VENA 색상 기반 로그인 배경
final class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                Color(0xFFF0F7FF),
                AppColors.lightBlue,
              ],
              stops: [0.0, 0.58, 1.0],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              color: Color(0x183B82F6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              color: Color(0x1FF59CB3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
