class LoginResponse {
  String token;
  String refreshToken;

  LoginResponse({
    required this.token,
    required this.refreshToken,
  });

  LoginResponse copyWith({
    String? token,
    String? refreshToken,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  LoginResponse.fromJson(Map<String, dynamic> json)
      : token = json['token'] as String? ?? '',
        refreshToken = json['refreshToken'] as String? ?? '';

}