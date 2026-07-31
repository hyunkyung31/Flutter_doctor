// Django 로그인 API가 반환하는 성공 응답
final class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.doctorId,
    required this.doctorName,
  });

  final String accessToken;
  final String refreshToken;
  final String doctorId;
  final String doctorName;

// json 응답을 LoginResponse 객체로 변환 --> Flutter에서 사용
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(accessToken: json['access'] as String,
    refreshToken: json['refresh'] as String,
    doctorId: json['doctor_id'] as String,
    doctorName: json['doctor_name'] as String,);
  }
}