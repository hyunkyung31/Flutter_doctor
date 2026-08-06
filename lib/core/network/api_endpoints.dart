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

  // 협진 요청
  static const String consultations = '/api/consultations/';

  // 의료진 임상 보고서 목록 조회 및 초안 생성
  static const String emrSignOffs = '/api/emr-signoffs/';

  // 의료진 임상 보고서 상세 조회 및 수정
  static String emrSignOffDetail(int signOffId) {
    return '/api/emr-signoffs/$signOffId/';
  }

  // 최종 승인된 임상 보고서의 PDF 생성 및 다운로드
  // POST 요청은 PDF 생성, GET 요청은 생성된 PDF 다운로드에 사용
  static String emrSignOffReport(int signOffId) {
    return '/api/emr-signoffs/$signOffId/report/';
  }

  // 생성 완료된 임상 보고서의 전달 상태 처리
  static String emrSignOffTransmit(int signOffId) {
    return '/api/emr-signoffs/$signOffId/transmit/';
  }

  // 채팅방
  static const String chatRooms = '/api/chat/rooms/';

  // 메모
  static const String memos = '/api/memos/';
  static const String voiceMemos = '/api/memos/voice/';

  static String chatMessages(String roomId) {
    return '/api/chat/rooms/$roomId/messages/';
  }

  static String chatRoomRead(String roomId) {
    return '/api/chat/rooms/$roomId/read/';
  }

  static String chatResourceStatus(String messageId) {
    return '/api/chat/messages/$messageId/resource-status/';
  }

  static String consultationStatus(String consultationId) {
    return '/api/consultations/$consultationId/status/';
  }

  // 환자 상세 조회
  static String patientDetail(String patientId) {
    return '/api/patients/$patientId/';
  }

  static String consultationComplete(String consultationId) {
    return '/api/consultations/$consultationId/complete/';
  }

  // 검사 키프레임 통합 AI 분석 및 결과 저장
  static String examAiRun(int examId) {
    return '/api/exams/$examId/ai/run/';
  }

  // 메모
  static String memoDetail(int memoId) {
    return '/api/memos/$memoId/';
  }

  static String memoAudio(int memoId) {
    return '/api/memos/$memoId/audio/';
  }

  // 진료 예약 (Django Appointment)
  static const String appointments = '/api/appointments/';

  static String appointmentDetail(String appointmentId) {
    return '/api/appointments/$appointmentId/';
  }

  // 알림
  static const String notifications = '/api/notifications/';

  static String notificationRead(int notificationId) {
    return '/api/notifications/$notificationId/read/';
  }
}
