import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/network/token_interceptor.dart';
import 'package:ecommerce_app_huma_volve/core/network/token_storage.dart';
import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';

// /auth/login
class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.escuelajs.co/api/v1',
  );

  late final Dio _dio;
  final TokenStorage tokenStorage;

  ApiClient({
    required this.tokenStorage,
    String baseUrl = defaultBaseUrl,
    Duration timeout = const Duration(seconds: 60),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,

        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
    );

    /// Optional Logging
    _dio.interceptors.add(SafeLogInterceptor(
      logPrint: (object) {
        // You can customize logging here, e.g., using a logging package
        debugPrint('[API] $object');
      },
    ));
    // You can also add interceptors for authentication, error handling, etc.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can add common headers or logging here
          // For example, add a custom header:
          // options.headers['X-Custom-Header'] = 'value';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // You can handle responses globally here
          return handler.next(response);
        },
        onError: (error, handler) {
          // You can handle errors globally here
          return handler.next(error);
        },
      ),
    );
    _dio.interceptors.add(TokenInterceptor(tokenStorage, _dio, baseUrl: baseUrl));
  }

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> put(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
    );
  }

  /// PUT with multipart/form-data body (e.g. for file uploads).
  Future<Map<String, dynamic>> putFormData(
      String path, {
        required FormData formData,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.put(
        path,
        data: formData,
        options: Options(
          headers: {
            ...?headers,
            HttpHeaders.contentTypeHeader: 'multipart/form-data',
          },
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const ServerException(
          message: 'Invalid server response.',
        );
      }

      final success = data['success'];
      if (success is bool && !success) {
        throw ServerException(
          message: _readString(data, 'message') ?? 'Request failed.',
          code: _readString(data, 'errorCode') ?? _readString(data, 'code'),
          statusCode: response.statusCode,
          data: data['data'],
        );
      }

      return data;
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on FormatException {
      throw const ServerException(
        message: 'Invalid response format.',
      );
    }
  }

  Future<Map<String, dynamic>> patch(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    return _request(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> delete(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      headers: headers,
    );
  }

  /// POST that returns raw binary bytes (e.g. PDF generation endpoint).
  /// Uses [ResponseType.bytes] so Dio does not attempt JSON parsing.
  Future<List<int>> postBytes(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            HttpHeaders.acceptHeader: 'application/pdf, application/octet-stream',
            ...?headers,
          },
        ),
      );
      final data = response.data;
      if (data is List<int>) return data;
      if (data is List) return List<int>.from(data);
      throw const ServerException(message: 'Expected binary PDF response.');
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {
            ...?headers,
          },
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const ServerException(
          message: 'Invalid server response.',
        );
      }

      /// Handle API success flag
      final success = data['success'];

      if (success is bool && !success) {
        throw ServerException(
          message:
          _readString(data, 'message') ??
              'Request failed.',
          code:
          _readString(data, 'errorCode') ??
              _readString(data, 'code'),
          statusCode: response.statusCode,
          data: data['data'],
        );
      }

      return data;
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on FormatException {
      throw const ServerException(
        message: 'Invalid response format.',
      );
    }
  }

  Exception _handleDioException(DioException error) {
    /// Server responded with error
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        return ServerException(
          message:
          _readString(data, 'message') ??
              'Request failed.',
          code:
          _readString(data, 'errorCode') ??
              _readString(data, 'code'),
          statusCode: error.response?.statusCode,
          data: data['data'],
        );
      }

      return ServerException(
        message: 'Server error occurred.',
        statusCode: error.response?.statusCode,
      );
    }

    /// Timeout
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException(
        'The request timed out.',
      );
    }

    /// No internet
    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Unable to connect to the server.',
      );
    }

    /// SSL / certificate issues
    if (error.error is HandshakeException) {
      return const NetworkException(
        'Secure connection failed.',
      );
    }

    return const NetworkException(
      'Unexpected network error occurred.',
    );
  }

  String? _readString(
      Map<String, dynamic> json,
      String key,
      ) {
    final value = json[key];
    return value is String ? value : null;
  }
}

class SafeLogInterceptor extends Interceptor {
  final void Function(Object object)? logPrint;

  SafeLogInterceptor({this.logPrint});

  void _print(Object object) {
    if (logPrint != null) {
      logPrint!(object);
    } else {
      debugPrint(object.toString());
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _print('*** Request ***');
    _print('Uri: ${options.uri}');
    _print('Method: ${options.method}');

    final sanitizedHeaders = <String, dynamic>{};
    options.headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        sanitizedHeaders[key] = 'Bearer [SECURED]';
      } else {
        sanitizedHeaders[key] = value;
      }
    });
    _print('Headers: $sanitizedHeaders');

    if (options.data != null) {
      _print('RequestBody: ${_sanitizeData(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _print('*** Response ***');
    _print('Uri: ${response.requestOptions.uri}');
    _print('StatusCode: ${response.statusCode}');
    if (response.data != null) {
      _print('ResponseBody: ${_sanitizeData(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _print('*** DioException ***');
    _print('Uri: ${err.requestOptions.uri}');
    _print('Message: ${err.message}');
    if (err.response != null) {
      _print('StatusCode: ${err.response?.statusCode}');
      if (err.response?.data != null) {
        _print('ResponseBody: ${_sanitizeData(err.response!.data)}');
      }
    }
    handler.next(err);
  }

  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    if (data.runtimeType.toString() == 'FormData') {
      return '[FORM DATA SECURED]';
    }
    if (data is Map) {
      final sanitizedMap = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (keyStr.contains('token') || keyStr.contains('password')) {
          sanitizedMap[key.toString()] = '[SECURED]';
        } else {
          sanitizedMap[key.toString()] = _sanitizeData(value);
        }
      });
      return sanitizedMap;
    } else if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    } else if (data is String) {
      try {
        final Object? decoded = jsonDecode(data);
        if (decoded != null) {
          return jsonEncode(_sanitizeData(decoded));
        }
      } catch (_) {}

      if (data.toLowerCase().contains('token') || data.toLowerCase().contains('password')) {
        return '[SECURED STRING]';
      }
    }
    return data;
  }
}