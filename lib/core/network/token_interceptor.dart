import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/network/token_storage.dart';

import 'api_endpoints.dart';

class TokenInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio _dio; // Main Dio instance used for retrying requests
  final Dio _refreshDio; // Isolated Dio instance for refresh calls

  bool _isRefreshing = false;
  final _requestQueue = <Map<String, dynamic>>[];

  TokenInterceptor(this.tokenStorage, this._dio, {required String baseUrl})
      : _refreshDio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Exclude certain endpoints from requiring a token
    if (!options.path.contains(ApiEndpoints.login) &&
        !options.path.contains(ApiEndpoints.refreshToken)
    ) {
      final accessToken = await tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If it's a 401 error, and NOT from the refresh endpoint itself
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      _requestQueue.add({
        'handler': handler,
        'options': err.requestOptions,
      });

      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshToken = await tokenStorage.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            await tokenStorage.clearTokens();
            _rejectAll(err);
            return;
          }

          final response = await _refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          final data = response.data;
          if (data is Map<String, dynamic> && data['success'] == true) {
            final newAccessToken = data['data']['accessToken'];
            final newRefreshToken = data['data']['refreshToken'];

            if (newAccessToken != null && newRefreshToken != null) {
              await tokenStorage.updateTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Snapshot and clear the queue *before* awaiting any retries.
              // Otherwise a request that fails with 401 while we're mid-loop
              // (each retry `await`s, so the event loop can run other code)
              // would append to `_requestQueue` while we're iterating it,
              // causing a ConcurrentModificationError, and then get wiped
              // out by the `_requestQueue.clear()` below without ever being
              // resolved or rejected.
              final pendingRequests =
              List<Map<String, dynamic>>.from(_requestQueue);
              _requestQueue.clear();

              // Retry queued requests
              for (final request in pendingRequests) {
                final RequestOptions options = request['options'];
                final ErrorInterceptorHandler currentHandler = request['handler'];

                options.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final retryResponse = await _dio.fetch(options);
                  currentHandler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  currentHandler.next(retryError);
                } catch (e) {
                  currentHandler.next(DioException(requestOptions: options, error: e));
                }
              }
              return;
            }
          }

          // Refresh failed or returned invalid format
          await tokenStorage.clearTokens();
          _rejectAll(err);
        } catch (e) {
          // Network error or 401 during refresh
          await tokenStorage.clearTokens();
          _rejectAll(err);
        } finally {
          _isRefreshing = false;
        }
      }
      return;
    }

    return handler.next(err);
  }

  void _rejectAll(DioException err) {
    for (final request in _requestQueue) {
      final ErrorInterceptorHandler handler = request['handler'];
      handler.next(err);
    }
    _requestQueue.clear();
  }
}