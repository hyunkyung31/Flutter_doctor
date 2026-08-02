import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/token_refresh_response.dart';
import '../model/current_doctor_response.dart';


final class AuthService {
  AuthService(this._apiClient);

// 공통 서버 주소와 타임아웃이 설정된 API 클라이언트
  final ApiClient _apiClient;
  // 로그인 성공 시 access, refresh 토큰, 의료진 아이디 + 이름 포함 LoginResponse 반환
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post<dynamic>(ApiEndpoints.login,
      data: request.toJson(),);

      final responseData = response.data;

      if (responseData is! Map) { // json이 아닐 때
        throw const AuthServiceException("서버의 로그인 형식이 올바르지 않습니다.",);
    }
      return LoginResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );
  } on DioException catch (error) {
    throw AuthServiceException(_messageFromDioException(error),);
  } on TypeError { // access, refresh 등 필드가 없거나 타입이 다를 때
    throw const AuthServiceException("로그인 응답 데이터 형식이 올바르지 않습니다.",);
  }
  }

  // 저장된 refresh 토큰으로 새 access 토큰 발급
  Future<TokenRefreshResponse> refreshAccessToken(
    String refreshToken,
  ) async {
    try {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.tokenRefresh,
        data: <String, dynamic>{
          'refresh': refreshToken,
        },
      );
      final responseData = response.data;

      if (responseData is! Map) {
        throw const AuthServiceException(
          "토큰 재발급 응답 형식이 올바르지 않습니다.",
        );
      }

      return TokenRefreshResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      throw AuthServiceException(
        _messageFromRefreshDioException(error),
        shouldClearSession: _isRefreshSessionInvalid(error),
      );
    } on TypeError {
      throw const AuthServiceException(
        "토큰 재발급 응답 데이터 형식이 올바르지 않습니다.",
      );
    }
  }

  bool _isRefreshSessionInvalid(DioException error) {
    if (error.type != DioExceptionType.badResponse) {
      return false;
    }
    final statusCode = error.response?.statusCode;

    return statusCode == 400 || statusCode == 401;
  }

  bool _isCurrentDoctorUnauthorized(DioException error) {
    if (error.type != DioExceptionType.badResponse) {
      return false;
    }

    final statusCode = error.response?.statusCode;

    return statusCode == 401 || statusCode ==403;
  }

  // 다른 private 메서드들

  // 새 Access Token을 이용하여 현재 의료진 정보 조회
  Future<CurrentDoctorResponse> getCurrentDoctor(
    String accessToken,
  ) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.me,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const AuthServiceException(
          "의료진 정보 응답 형식이 올바르지 않습니다.",
        );
      }

      return CurrentDoctorResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      throw AuthServiceException(
        _messageFromCurrentDoctorDioException(error),
        shouldClearSession: _isCurrentDoctorUnauthorized(error),
      );
    } on TypeError {
      throw const AuthServiceException(
        "의료진 정보 응답 데이터 형식이 올바르지 않습니다.",
      );
    }
  }

// 일반 로그인 시 Dio에서 발생한 네트워크 오류를 로그인 화면에 표시할 메세지로 반환
  String _messageFromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return "서버 응답 시간이 초과되었습니다.";

      case DioExceptionType.connectionError:
        return "서버에 연결할 수 없습니다.";
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if(statusCode == 400 || statusCode == 401) {
          return "아이디 또는 비밀번호를 확인해 주세요.";
        }
        return "로그인 요청을 처리하지 못했습니다.";

      case DioExceptionType.cancel:
        return "로그인 요청이 취소되었습니다.";

      case DioExceptionType.badCertificate:
        return "서버 인증서를 확인할 수 없습니다.";

      case DioExceptionType.unknown:
        return "네트워크 오류가 발생했습니다.";
    }
  }

   // Refresh Token 재발급 중 발생한 Dio 오류를 메시지로 변환
  String _messageFromRefreshDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return '로그인 세션 확인 시간이 초과되었습니다.';

      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 400 || statusCode == 401) {
          return '저장된 로그인 세션이 만료되었습니다.';
        }

        return '로그인 세션을 복원하지 못했습니다.';

      case DioExceptionType.cancel:
        return '로그인 세션 확인이 취소되었습니다.';

      case DioExceptionType.badCertificate:
        return '서버 인증서를 확인할 수 없습니다.';

      case DioExceptionType.unknown:
        return '로그인 세션 확인 중 네트워크 오류가 발생했습니다.';
    }
  }

  // 현재 의료진 정보 조회 중 발생한 Dio 오류를 메시지로 변환
  String _messageFromCurrentDoctorDioException(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return '의료진 정보 조회 시간이 초과되었습니다.';

      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          return '의료진 인증 정보를 확인할 수 없습니다.';
        }

        return '의료진 정보를 불러오지 못했습니다.';

      case DioExceptionType.cancel:
        return '의료진 정보 조회가 취소되었습니다.';

      case DioExceptionType.badCertificate:
        return '서버 인증서를 확인할 수 없습니다.';

      case DioExceptionType.unknown:
        return '의료진 정보 조회 중 네트워크 오류가 발생했습니다.';
    }
  }

}

final class AuthServiceException implements Exception {
  const AuthServiceException(
    this.message, {
      this.shouldClearSession = false,
    });

  final String message;
  final bool shouldClearSession;

  @override
  String toString() => message;
}
