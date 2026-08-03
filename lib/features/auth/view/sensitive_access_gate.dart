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
    extends State<SensitiveAccessGate>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _isAuthorized = false;
  bool _isAppInForeground = true;  // 앱이 사용자에게 표시되고 입력을 받을 수 있는 상태인지 기록
  String? _errorMessage;


  @override
  void initState() {
    super.initState();

    // 앱의 resumed, inactive, paused 등의 상태 변화를 감지
    WidgetsBinding.instance.addObserver(this);

    final lifecycleState =
        WidgetsBinding.instance.lifecycleState;

    // 초기 상태가 없거나 정상 실행 상태인 경우에만 민감정보 화면의 인증을 시작
    _isAppInForeground =
        lifecycleState == null ||
        lifecycleState ==
            AppLifecycleState.resumed;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isAppInForeground) {
        return;
      }

      _authorize();
    });
  }

  @override
  void dispose() {
    // 화면이 제거되면 주기 감시 해제
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

    @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (!mounted) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 돌아오면 기존 인증의 5분 유효시간 다시 확인
      setState(() {
        _isAppInForeground = true;
      });

      _authorize();
      return;
    }

    // 앱이 비활성화되거나 백그라운드로 이동하면 민감정보 화면 즉시 가리기
    // SensitiveAuthService의 마지막 인증 시각은 삭제하지 않음 - 5분 이내에 복귀하면 생체인증 창 없이 다시 승인
    setState(() {
      _isAppInForeground = false;
      _isAuthorized = false;
      _errorMessage = null;
    });
  }


  Future<void> _authorize() async {
    if (_isAuthenticating || !_isAppInForeground) {
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

          // 인증 도중 백그라운드로 이동하면 성공해도 민감정보 표시하지 않음
          _isAuthorized = _isAppInForeground;
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
    // 앱이 포그라운드이고 인증된 경우에만 민감정보 표시
    if (_isAppInForeground && _isAuthorized) {
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