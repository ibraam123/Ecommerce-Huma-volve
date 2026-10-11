abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}
