// Django  로그인  API에 전달할 요청 데이터
// 로그인 화면에서 입력한 아이디 , 비밀번호를 JSON 구조로 변환
final class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
  });
  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}