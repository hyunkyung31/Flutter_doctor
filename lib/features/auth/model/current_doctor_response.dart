// 현재 Access Token에 연결된 의료진 정보 응답
final class CurrentDoctorResponse {
  const CurrentDoctorResponse({
    required this.id,
    required this.username,
    required this.email,
  });

  final int id;
  final String username;
  final String email;

  // Flutter의 기존 인증 상태에서 사용하는 형식으로 변환
  String get doctorId => id.toString();
  String get doctorName => username;

  factory CurrentDoctorResponse.fromJson(Map<String, dynamic> json) {
    return CurrentDoctorResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}