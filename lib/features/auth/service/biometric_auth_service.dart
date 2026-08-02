import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

enum BiometricAuthResult {
  authenticated,  // 생체 인식 성공 후 Refresh Token 세션 복원 진행
  unavailable,    // 생체인식 미지원 기기 - 일반 로그인 화면 이동
  notEnrolled,    // 지문이나 얼굴이 등록되지 않았음 - 일반 로그인 화면 이동
  lockedOut,      // 반복 실패로 잠금 상태 - 일반 로그인 화면 이동
  failed,         // 사용자 취소 또는 인증 실패 - 일반 로그인 화면 이동
}

final class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication =
           localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  // 기기가 생체인식을 지원하는지 확인
  Future<bool> canAuthenticate() async {
    try {
      return await _localAuthentication.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  // 저장된 로그인 세션 복원 전에 생체인식 수행
  Future<BiometricAuthResult> authenticate({
    String localizedReason = "저장된 의료진 정보를 사용하려면 생체인증이 필요합니다.",
  }) async {
    try {
      final canCheckBiometrics =
          await _localAuthentication.canCheckBiometrics;

      if (!canCheckBiometrics) {
        return BiometricAuthResult.unavailable;
      }

      final authenticated =
          await _localAuthentication.authenticate(
            localizedReason: localizedReason,
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
              useErrorDialogs: false,
            ),
          );

      if (authenticated) {
        return BiometricAuthResult.authenticated;
      }

      return BiometricAuthResult.failed;
    } on PlatformException catch (error) {
      switch (error.code) {
        case auth_error.notAvailable:
          return BiometricAuthResult.unavailable;

        case auth_error.notEnrolled:
          return BiometricAuthResult.notEnrolled;

        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricAuthResult.lockedOut;

        default:
          return BiometricAuthResult.failed;
      }
    }
  }
}