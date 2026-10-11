
import 'exceptions.dart';
import 'failures.dart';

class MabFailure {
  static Failure mapFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 401) {
        return UnauthorizedFailure(
          message: error.message,
          code: error.code,
          statusCode: error.statusCode,
        );
      }
      if (error.statusCode == 400 || error.code == 'VALIDATION_ERROR') {
        return ValidationFailure(
          message: error.message,
          code: error.code,
          statusCode: error.statusCode,
        );
      }
      return ServerFailure(
        message: error.message,
        code: error.code,
        statusCode: error.statusCode,
      );
    }

    if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    }

    if (error is CacheException) {
      return CacheFailure(message: error.message);
    }

    if (error is FormatException) {
      return ServerFailure(message: error.message);
    }

    return UnknownFailure(message: error.toString());
  }

}