import 'biometric_auth_service.dart';

enum SensitiveAuthResult {
  authorized,
  unavailable,
  notEnrolled,
  lockedOut,
  denied,
}

final class SensitiveAuthService {
  SensitiveAuthService({
    required this._biometricAuthService,
    this._authenticationValidity = const Duration(minutes: 5),
    DateTime Function()? currentTime,
  }) : _currentTime = currentTime ?? DateTime.now;

  final BiometricAuthService _biometricAuthService;
  final Duration _authenticationValidity;
  final DateTime Function() _currentTime;

  DateTime? _lastAuthenticatedAt;

  DateTime? get lastAuthenticatedAt => _lastAuthenticatedAt;

  bool get isAuthenticationValid {
    final lastAuthenticatedAt = _lastAuthenticatedAt;

    if (lastAuthenticatedAt == null) {
      return false;
    }

    final elapsed = _currentTime().difference(
      lastAuthenticatedAt,
    );

    return !elapsed.isNegative &&
        elapsed < _authenticationValidity;
  }

  Future<SensitiveAuthResult> authorize({
    required String localizedReason,
    bool forceAuthentication = false,
  }) async {
    if (!forceAuthentication && isAuthenticationValid) {
      return SensitiveAuthResult.authorized;
    }

    final biometricResult =
        await _biometricAuthService.authenticate(
          localizedReason: localizedReason,
        );

    switch (biometricResult) {
      case BiometricAuthResult.authenticated:
        _lastAuthenticatedAt = _currentTime();
        return SensitiveAuthResult.authorized;

      case BiometricAuthResult.unavailable:
        return SensitiveAuthResult.unavailable;

      case BiometricAuthResult.notEnrolled:
        return SensitiveAuthResult.notEnrolled;

      case BiometricAuthResult.lockedOut:
        return SensitiveAuthResult.lockedOut;

      case BiometricAuthResult.failed:
        return SensitiveAuthResult.denied;
    }
  }

  void invalidate() {
    _lastAuthenticatedAt = null;
  }
}