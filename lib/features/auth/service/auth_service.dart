import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';


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
// Dio에서 발생한 네트워크 오류를 로그인 화면에 표시할 문자열로 변환
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
}

final class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
