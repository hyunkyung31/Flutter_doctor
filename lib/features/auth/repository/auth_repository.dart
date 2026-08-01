import '../../../core/storage/secure_storage.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../service/auth_service.dart';

// 로그인 API 호출과 인증 토큰 저장을 연결하는 저장소
// AuthService - 서버 통신을 담당하고,
// SecureStorage - 토큰의 안전한 기기 저장을 담당
final class AuthRepository {
  AuthRepository(
    this._authService,
    this._secureStorage,
  );

  final AuthService _authService;
  final SecureStorage _secureStorage;

  // 아이디와 비밀번호로 로그인
  /// 서버 로그인이 성공하면 Access Token과 Refresh Token을 기기의 보안 저장소에 저장한 뒤 로그인 응답 반환
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await _authService.login(
      LoginRequest(
        username: username,
        password: password,
      ),
    );

    try {
      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on Exception {
      await _clearTokensSafely();

      throw const AuthRepositoryException(
        '로그인 정보를 안전하게 저장하지 못했습니다.',
      );
    }

    return response;
  }

  // 로그아웃할 때 저장된 인증 토큰을 모두 삭제
  Future<void> logout() {
    return _secureStorage.clearTokens();
  }

  // 저장된 Access Token 반환
  // 이후 자동 로그인 여부 확인이나 인증 헤더 설정에 사용
  Future<String?> readAccessToken() {
    return _secureStorage.readAccessToken();
  }

  // 저장된 Refresh Token 반환
  // 이후 Access Token 재발급 기능에서 사용
  Future<String?> readRefreshToken() {
    return _secureStorage.readRefreshToken();
  }

  // 기기에 사용할 수 있는 Access Token이 저장되어 있는지 확인
  Future<bool> hasAccessToken() async {
    final accessToken = await _secureStorage.readAccessToken();

    return accessToken != null && accessToken.trim().isNotEmpty;
  }

  // 토큰 저장 중 일부만 저장되는 상황을 방지하기 위해 저장 실패 시 남아 있을 수 있는 토큰을 정리
  Future<void> _clearTokensSafely() async {
    try {
      await _secureStorage.clearTokens();
    } on Exception {
      return;
    }
  }
}

// 로그인 처리와 토큰 저장 과정에서 발생한 오류
final class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}