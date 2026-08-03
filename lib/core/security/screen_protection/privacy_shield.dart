import 'package:flutter/material.dart';

import 'privacy_screen.dart';

// 앱 비활성화되거나 백그라운드 이동 시 보호 화면 표시, 앱 활성화 시 제거

class PrivacyShield extends StatefulWidget {
  const PrivacyShield({required this.child, super.key});

  // 보호 화면 아래에서 원래 표시되는 앱 화면
  final Widget child;

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield>
    with WidgetsBindingObserver {
  bool _isPrivacyScreenVisible = false;

  @override
  void initState() {
    super.initState();

    // 운영체제가 전달하는 앱 생명주기 변화를 받기 위해 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 위젯이 제거된 뒤에도 생명주기 알림을 받지 않도록 해제
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool shouldShowPrivacyScreen = switch (state) {
      AppLifecycleState.resumed => false,
      AppLifecycleState.inactive => true,
      AppLifecycleState.hidden => true,
      AppLifecycleState.paused => true,
      AppLifecycleState.detached => true,
    };

    if (!mounted || shouldShowPrivacyScreen == _isPrivacyScreenVisible) {
      return;
    }

    setState(() {
      _isPrivacyScreenVisible = shouldShowPrivacyScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        // 보호 화면은 항상 위젯 트리에 유지하여 이미지를 미리 준비
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_isPrivacyScreenVisible,
            child: ExcludeSemantics(
              excluding: !_isPrivacyScreenVisible,
              child: Opacity(
                opacity: _isPrivacyScreenVisible ? 1 : 0,
                child: const PrivacyScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
