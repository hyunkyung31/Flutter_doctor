import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../service/sensitive_auth_service.dart';

final class SensitiveAccessGate extends StatefulWidget {
  const SensitiveAccessGate({
    super.key,
    required this.localizedReason,
    required this.child,
    this.forceAuthentication = false,
  });

  final String localizedReason;
  final Widget child;
  final bool forceAuthentication;

  @override
  State<SensitiveAccessGate> createState() =>
      _SensitiveAccessGateState();
}

final class _SensitiveAccessGateState
    extends State<SensitiveAccessGate> {
  bool _isAuthenticating = false;
  bool _isAuthorized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authorize();
    });
  }

  Future<void> _authorize() async {
    if (_isAuthenticating) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final result = await context
        .read<SensitiveAuthService>()
        .authorize(
          localizedReason: widget.localizedReason,
          forceAuthentication: widget.forceAuthentication,
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case SensitiveAuthResult.authorized:
        setState(() {
          _isAuthenticating = false;
          _isAuthorized = true;
          _errorMessage = null;
        });
        return;

      case SensitiveAuthResult.unavailable:
        _setFailure(
          '이 기기에서는 생체인증을 사용할 수 없습니다.',
        );
        return;

      case SensitiveAuthResult.notEnrolled:
        _setFailure(
          '기기에 등록된 생체정보가 없습니다.',
        );
        return;

      case SensitiveAuthResult.lockedOut:
        _setFailure(
          '생체인증이 잠겼습니다. 잠시 후 다시 시도해 주세요.',
        );
        return;

      case SensitiveAuthResult.denied:
        _setFailure(
          '생체인증이 취소되었거나 인증에 실패했습니다.',
        );
        return;
    }
  }

  void _setFailure(String message) {
    setState(() {
      _isAuthenticating = false;
      _isAuthorized = false;
      _errorMessage = message;
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/patient');
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorized) {
      return widget.child;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('본인 확인'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isAuthenticating
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        '생체인증을 확인하고 있습니다.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_person_outlined,
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ??
                            '민감정보 접근을 위해 본인 확인이 필요합니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _authorize,
                        child: const Text('다시 인증'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _goBack,
                        child: const Text('돌아가기'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}