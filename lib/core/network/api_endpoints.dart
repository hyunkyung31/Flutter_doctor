// 앱에서 사용하는 Django REST API 주소 및 경로 관리
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://34.80.83.7:8000',
  );

  // 의료진 로그인 API 상대 경로
  // 이후 DIO BASE URL과 결합
  static const String login = '/api/login/';
  static const String tokenRefresh = '/api/token/refresh/';    // 저장된 refresh Token으로 새 access Token을 발급
  static const String me ='/api/me/';                          // 현재 access Token에 해당하는 의료진 정보를 조회

  static const String patients = '/api/patients/';
  static const String patientSearch = '/api/patients/search/';
  static String patientDetail(String patientId) {
    return '/api/patients/$patientId/';
  }
}
