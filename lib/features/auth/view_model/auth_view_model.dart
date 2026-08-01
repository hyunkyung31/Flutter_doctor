import 'package:flutter/foundation.dart';
import '../repository/auth_repository.dart';
import '../service/auth_service.dart';

// 로그인 화면에서 사용할 인증 상태
enum AuthStatus {
  // 아직 로그인 요청을 수행하지 않은 초기 상태
  initial,

  // 로그인 요청을 처리 중인 상태
  loading,

  // 로그인과 토큰 저장 성공한 상태
  authenticated,

  // 로그인에 실패했거나 로그아웃된 상태
  unauthenticated,
}

// 로그인 화면과 인증 데이터 계층을 연결하는 ViewModel
// 화면의 입력값을 AuthRepository에 전달
// 로딩 상태, 오류 메시지, 로그인한 의료진 정보를 관리
final class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _doctorId;
  String? _doctorName;

  // 현재 인증 처리 상태
  AuthStatus get status => _status;

  // 로그인 요청이 진행 중인지 반환
  bool get isLoading => _status == AuthStatus.loading;

  // 로그인이 완료된 상태인지 반환
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // 로그인 화면에 표시할 오류 메시지
  String? get errorMessage => _errorMessage;

  // 로그인한 의료진의 서버 식별자.
  String? get doctorId => _doctorId;

  // 로그인한 의료진의 이름
  String? get doctorName => _doctorName;


  // 로그인과 토큰 저장이 모두 성공하면 true를 반환
  // 실패하면 오류 메시지를 저장한 뒤 false를 반환
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_status == AuthStatus.loading) {
      return false;
    }

    final trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || password.isEmpty) {
      _setFailure('아이디와 비밀번호를 모두 입력해 주세요.');
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(
        username: trimmedUsername,
        password: password,
      );

      _doctorId = response.doctorId;
      _doctorName = response.doctorName;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } on AuthServiceException catch (error) {
      _setFailure(error.message);
      return false;
    } on AuthRepositoryException catch (error) {
      _setFailure(error.message);
      return false;
    } on Exception {
      _setFailure('로그인 중 예상하지 못한 오류가 발생했습니다.');
      return false;
    }
  }

  // 저장된 토큰을 삭제하고 로그아웃 상태로 변경
  Future<bool> logout() async {
    try {
      await _authRepository.logout();

      _doctorId = null;
      _doctorName = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();

      return true;
    } on Exception {
      _errorMessage = '로그아웃 정보를 정리하지 못했습니다.';
      notifyListeners();

      return false;
    }
  }

  // 화면에 표시된 오류 메시지 제거
  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  // 로그인 실패 상태와 오류 메시지 저장
  void _setFailure(String message) {
    _status = AuthStatus.unauthenticated;
    _errorMessage = message;
    notifyListeners();
  }
}