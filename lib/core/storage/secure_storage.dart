import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

// 로그인 토큰을 보안 저장소에 저장, 관리
// Access Token과 refresh Token을 암호화된 저장소에 보관
final class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  // 로그인 성공 후 토큰 저장 (access , refresh 토큰 함께 저장)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required String doctorId,
    required String doctorName,
  }) async {
    await Future.wait([
      _storage.write(
        key: StorageKeys.accessToken,
        value: accessToken,
      ),
      _storage.write(
        key: StorageKeys.refreshToken,
        value: refreshToken,
      ),
      _storage.write(
        key: StorageKeys.doctorId,
        value: doctorId,
      ),
      _storage.write(
        key: StorageKeys.doctorName,
        value: doctorName,
      ),
    ]);
  }


  // refresh Token 재발급 성공 후 새 access Token만 교체 저장
  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(
      key: StorageKeys.accessToken,
      value: accessToken,);
  }

  Future<String?> readDoctorId() {
    return _storage.read(
      key: StorageKeys.doctorId,
    );
  }

  Future<String?> readDoctorName() {
    return _storage.read(
      key: StorageKeys.doctorName,
    );
  }

  // 토큰 읽기
  Future<String?> readAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  // 로그아웃하거나 인증 상태 초기화 시 두 토큰 모두 삭제

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(
        key: StorageKeys.accessToken,
      ),
      _storage.delete(
        key: StorageKeys.refreshToken,
      ),
      _storage.delete(
        key: StorageKeys.doctorId,
      ),
      _storage.delete(
        key: StorageKeys.doctorName,
      ),
    ]);
  }
}