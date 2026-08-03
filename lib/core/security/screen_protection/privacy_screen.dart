import 'package:flutter/material.dart';

// 앱이 백그라운드로 이동할 때 표시하는 보호 화면
// 최근 앱 미리보기에서 보미 보안 화면만 노출

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String _assetPath = 'assets/images/privacy/bomi_privacy.png';

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFF8F8), // 휴대폰과 비율이 다를 때 남는 공간 채우기
      child: SizedBox.expand(
        child: SafeArea(
          child: Center(
            child: Image(
              image: AssetImage(_assetPath),
              fit: BoxFit.contain, // 전체 비율 유지, 화면 안에 맞추기
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
