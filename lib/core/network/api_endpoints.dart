// 앱에서 사용하는 Django REST API 주소 및 경로 관리
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://34.80.83.7:8000',
  );

  // 의료진 로그인 API
  static const String login = '/api/login/';

  // 저장된 Refresh Token으로 새 Access Token 발급
  static const String tokenRefresh = '/api/token/refresh/';

  // 현재 로그인한 의료진 정보 조회
  static const String me = '/api/me/';

  // 환자 목록 조회
  static const String patients = '/api/patients/';

  // 협진 대상 의료진 목록 조회
  static const String doctors = '/api/doctors/';

  // 환자 검색
  static const String patientSearch = '/api/patients/search/';

  // 환자 상세 조회
  static String patientDetail(String patientId) {
    return '/api/patients/$patientId/';
  }

  // 검사 키프레임 통합 AI 분석 및 결과 저장
  static String examAiRun(int examId,) {
    return '/api/exams/$examId/ai/run/';
  }
}
