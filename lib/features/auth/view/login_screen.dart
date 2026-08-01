import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/auth_view_model.dart';
import 'package:go_router/go_router.dart';

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

  // 입력값을 검사 후  AuthViewModel에 로그인 요청
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    // 로그인 요청, 토큰 저장 성공 여부 반환
    final isSuccess = await authViewModel.login(
      username: _usernameController.text,
      password: _passwordController.text,);

    // 비동기 로그인 처리 중 화면이 제거됐는지 확인
    if (!mounted) { return;}

    // 로그인 성공한 후 연결 화면 (현재 임시 화면 --> 홈 화면 구현 후 경로 교체!!)//////////////////////
    if (isSuccess) {context.go('/home');}

    await authViewModel.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginHeader(),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !authViewModel.isLoading,
                            autofillHints: const [
                              AutofillHints.username,
                            ],
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '아이디',
                              hintText: '의료진 아이디를 입력해 주세요.',
                              prefixIcon: Icon(
                                Icons.person_outline,
                              ),
                              border: OutlineInputBorder(),
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
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              hintText: '비밀번호를 입력해 주세요.',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon: IconButton(
                                onPressed: _togglePasswordVisibility,
                                tooltip: _obscurePassword
                                    ? '비밀번호 표시'
                                    : '비밀번호 숨기기',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              border: const OutlineInputBorder(),
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
                          const SizedBox(height: 16),
                          if (authViewModel.errorMessage != null)
                            _LoginMessage(
                              message: authViewModel.errorMessage!,
                              isError: true,
                            ),
                          if (authViewModel.isAuthenticated)
                            _LoginMessage(
                              message:
                                  '${authViewModel.doctorName ?? '의료진'}님, 로그인되었습니다.',
                              isError: false,
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  authViewModel.isLoading ? null : _submit,
                              child: authViewModel.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('로그인'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 로그인 화면 상단의 앱 이름과 설명
final class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 42,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'VENA',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '의료진 계정으로 로그인해 주세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// 로그인 성공 또는 실패 메시지
final class _LoginMessage extends StatelessWidget {
  const _LoginMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: foregroundColor),
      ),
    );
  }
}