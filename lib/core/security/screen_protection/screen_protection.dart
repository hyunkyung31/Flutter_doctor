import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Android 민감정보 화면의 스크린샷과 화면 녹화를 제어
// 민감 화면에 들어갈 때 acquire 호출, 해당 화면에서 벗어날 때 release 호출
final class ScreenCaptureProtection {
  ScreenCaptureProtection._();

  static const MethodChannel _channel = MethodChannel(
    'com.vena.doctor/screen_capture',
  );

  // 현재 캡처 방지를 요청 중인 민감 화면의 수
  static int _activeRequestCount = 0;

  // Android 호출이 요청된 순서대로 실행되도록 관리
  static Future<void> _pendingOperation = Future<void>.value();

  // 민감 화면 진입 시 캡처 방지를 활성화
  static Future<void> acquire() {
    _activeRequestCount += 1;

    // 첫 번째 민감 화면이 열릴 때만 FLAG_SECURE를 활성화
    if (_activeRequestCount != 1) {
      return Future<void>.value();
    }

    return _enqueue(
      enabled: true,
    );
  }

  // 민감 화면 이탈 시 캡처 방지 요청을 해제
  static Future<void> release() {
    // 잘못된 중복 해제로 카운트가 음수가 되는 것을 막음
    if (_activeRequestCount == 0) {
      return Future<void>.value();
    }

    _activeRequestCount -= 1;

    // 다른 민감 화면이 남아 있으면 캡처 방지를 유지
    if (_activeRequestCount != 0) {
      return Future<void>.value();
    }

    return _enqueue(
      enabled: false,
    );
  }

  // 활성화와 해제 요청이 서로 엇갈리지 않도록 순차 실행
  static Future<void> _enqueue({
    required bool enabled,
  }) {
    _pendingOperation = _pendingOperation.then(
      (_) => _setSecure(
        enabled: enabled,
      ),
    );

    return _pendingOperation;
  }

  /// Android MainActivity의 setSecure 메서드를 호출
  static Future<void> _setSecure({
    required bool enabled,
  }) async {
    //  Android 전용
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'setSecure',
        <String, Object>{
          'enabled': enabled,
        },
      );
    } on MissingPluginException catch (error) {
      debugPrint(
        '화면 캡처 방지 채널을 찾을 수 없습니다: $error',
      );
    } on PlatformException catch (error) {
      debugPrint(
        '화면 캡처 방지 상태 변경 실패: ${error.message}',
      );
    } catch (error) {
      debugPrint(
        '화면 캡처 방지 처리 중 예상하지 못한 오류가 발생했습니다: $error',
      );
    }
  }
}