class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Object? data;

  const ServerException({
    required this.message,
    this.code,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => message;
}