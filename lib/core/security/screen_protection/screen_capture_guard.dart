import 'dart:async';

import 'package:flutter/material.dart';

import 'screen_protection.dart';
import 'package:flutter/foundation.dart';

// 하위 화면이 표시되는 동안 Android 화면 캡처 차단
// FLAG_SECURE 활성화 요청이 완료되기 전까지는 하위 민감정보 화면을 표시하지 않음
final class ScreenCaptureGuard extends StatefulWidget {
  const ScreenCaptureGuard({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ScreenCaptureGuard> createState() {
    return _ScreenCaptureGuardState();
  }
}

final class _ScreenCaptureGuardState extends State<ScreenCaptureGuard> {
  bool _hasAcquiredProtection = false;
  bool _isProtectionReady = false;

  // 이전 비동기 요청의 완료 결과가 최신 상태를 덮어쓰지 않도록 구분
  int _operationVersion = 0;

  // 실제 배포용 release 빌드에서만 화면 캡처·녹화를 차단
  bool get _shouldEnableProtection {
    return widget.enabled && kReleaseMode;
  }

  @override
  void initState() {
    super.initState();

    _updateProtection();
  }

  @override
  void didUpdateWidget(covariant ScreenCaptureGuard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      _updateProtection();
    }
  }

  void _updateProtection() {
    final operationVersion = ++_operationVersion;

    if (!_shouldEnableProtection) {
      _releaseProtection();
      _isProtectionReady = true;
      return;
    }

    _isProtectionReady = false;

    unawaited(_acquireProtection(operationVersion));
  }

  Future<void> _acquireProtection(int operationVersion) async {
    if (!_hasAcquiredProtection) {
      _hasAcquiredProtection = true;

      await ScreenCaptureProtection.acquire();
    }

    if (!mounted ||
        operationVersion != _operationVersion ||
        !_hasAcquiredProtection) {
      return;
    }

    setState(() {
      _isProtectionReady = true;
    });
  }

  void _releaseProtection() {
    if (!_hasAcquiredProtection) {
      return;
    }

    _hasAcquiredProtection = false;

    unawaited(ScreenCaptureProtection.release());
  }

  @override
  void dispose() {
    ++_operationVersion;
    _releaseProtection();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldEnableProtection && !_isProtectionReady) {
      return const ColoredBox(
        color: Color(0xFFF8FAFC),
        child: SizedBox.expand(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return widget.child;
  }
}
