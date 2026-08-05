import '../../../core/storage/secure_storage.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../service/auth_service.dart';

// 로그인 API 호출과 인증 정보 저장을 연결하는 저장소
// AuthService는 서버 통신을 담당하고,
// SecureStorage는 인증 정보를 기기의 보안 저장소에 보관한다.
final class AuthRepository {
  AuthRepository(this._authService, this._secureStorage);

  final AuthService _authService;
  final SecureStorage _secureStorage;

  // 아이디와 비밀번호로 로그인한다.
  // 서버 로그인이 성공하면 토큰과 의료진 정보를 보안 저장소에 저장한다.
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await _authService.login(
      LoginRequest(username: username, password: password),
    );

    try {
      await _secureStorage.saveLoginSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        doctorId: response.doctorId,
        doctorName: response.doctorName,
      );
    } on Exception {
      await _clearTokensSafely();

      throw const AuthRepositoryException('로그인 정보를 안전하게 저장하지 못했습니다.');
    }

    return response;
  }

  // 저장된 Refresh Token으로 서버 세션을 갱신하고,
  // 보안 저장소에서 의료진 ID와 이름을 복원한다.
  Future<RestoredDoctorSession?> restoreSession() async {
    final refreshToken = await _secureStorage.readRefreshToken();

    final normalizedRefreshToken = refreshToken?.trim();

    // 저장된 Refresh Token이 없으면 자동 로그인 대상이 아니다.
    if (normalizedRefreshToken == null || normalizedRefreshToken.isEmpty) {
      return null;
    }

    // Refresh Token으로 새 Access Token을 발급받아
    // 서버 로그인 세션이 유효한지 확인한다.
    final tokenResponse = await _authService.refreshAccessToken(
      normalizedRefreshToken,
    );

    String? doctorId;
    String? doctorName;

    try {
      doctorId = (await _secureStorage.readDoctorId())?.trim();

      doctorName = (await _secureStorage.readDoctorName())?.trim();
    } on Exception {
      await _clearTokensSafely();

      throw const AuthRepositoryException('저장된 의료진 정보를 불러오지 못했습니다.');
    }

    // 기존 로그인 세션에는 의료진 정보가 저장되어 있지 않을 수 있다.
    if (doctorId == null ||
        doctorId.isEmpty ||
        doctorName == null ||
        doctorName.isEmpty) {
      await _clearTokensSafely();

      throw const AuthRepositoryException('저장된 의료진 정보가 없어 일반 로그인이 필요합니다.');
    }

    try {
      await _secureStorage.saveAccessToken(tokenResponse.accessToken);
    } on Exception {
      await _clearTokensSafely();

      throw const AuthRepositoryException('갱신된 로그인 정보를 안전하게 저장하지 못했습니다.');
    }

    return RestoredDoctorSession(doctorId: doctorId, doctorName: doctorName);
  }

  // 로그아웃할 때 저장된 토큰과 의료진 정보를 모두 삭제한다.
  Future<void> logout() {
    return _secureStorage.clearTokens();
  }

  // 저장된 Access Token을 반환한다.
  Future<String?> readAccessToken() {
    return _secureStorage.readAccessToken();
  }

  // 저장된 Refresh Token을 반환한다.
  Future<String?> readRefreshToken() {
    return _secureStorage.readRefreshToken();
  }

  // 사용할 수 있는 Access Token이 저장되어 있는지 확인한다.
  Future<bool> hasAccessToken() async {
    final accessToken = await _secureStorage.readAccessToken();

    return accessToken != null && accessToken.trim().isNotEmpty;
  }

  // 자동 로그인에 사용할 수 있는 Refresh Token이 저장되어 있는지 확인한다.
  Future<bool> hasRefreshToken() async {
    final refreshToken = await _secureStorage.readRefreshToken();

    return refreshToken != null && refreshToken.trim().isNotEmpty;
  }

  // 저장 실패 시 일부 인증 정보만 남지 않도록 정리한다.
  Future<void> _clearTokensSafely() async {
    try {
      await _secureStorage.clearTokens();
    } on Exception {
      return;
    }
  }
}

// 생체 로그인이나 자동 로그인으로 복원한 의료진 정보
final class RestoredDoctorSession {
  const RestoredDoctorSession({
    required this.doctorId,
    required this.doctorName,
  });

  final String doctorId;
  final String doctorName;
}

// 로그인 처리와 인증 정보 저장 과정에서 발생한 오류
final class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
