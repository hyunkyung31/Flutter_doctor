// Django Refresh Token API가 반환하는 성공 응답
final class TokenRefreshResponse {
  const TokenRefreshResponse({
    required this.accessToken,
  });

  final String accessToken;

  // JSON 응답을 TokenRefreshResponse 객체로 변환
  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(
      accessToken: json['access'] as String,
    );
  }
}