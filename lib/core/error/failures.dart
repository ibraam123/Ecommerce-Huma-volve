abstract class Failure {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure({
    required this.message,
    this.code,
    this.statusCode,
  });

}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.statusCode,
  });
}