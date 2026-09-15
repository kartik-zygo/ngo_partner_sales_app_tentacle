import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../services/secure_storage_service.dart';

class DioClient {
  DioClient._(this._dio);

  static DioClient? _instance;
  final Dio _dio;

  static DioClient get instance {
    _instance ??= DioClient._(_buildDio());
    return _instance!;
  }

  Dio get dio => _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor(dio));
    dio.interceptors.add(_ApiLogInterceptor());
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  final _storage = const SecureStorageService();
  bool _isRefreshing = false;
  final List<void Function()> _pendingRetries = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Never attempt a token refresh for the auth endpoints themselves.
    // A 401 from /auth/refresh (expired refresh token) or /auth/login must
    // propagate as a normal error — otherwise it re-enters this interceptor
    // while _isRefreshing is true, gets queued, and the awaited refresh call
    // never completes, hanging the app on the splash screen.
    final path = err.requestOptions.path;
    final isAuthEndpoint =
        path.contains('/auth/refresh') || path.contains('/auth/login');
    // Password-checked requests answer a wrong password with 401 as well. A
    // refresh cannot fix that, and the retry's own 401 would be queued behind
    // the refresh in progress, so the request would never complete.
    final isPasswordCheck = path.endsWith('/auth/me/password') ||
        (path.endsWith('/auth/me') && err.requestOptions.method == 'DELETE');

    if (err.response?.statusCode != 401 || isAuthEndpoint || isPasswordCheck) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Queue this retry until refresh completes
      _pendingRetries.add(() async {
        try {
          final token = await _storage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
        } catch (_) {
          handler.reject(err);
        }
      });
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) throw Exception('No refresh token stored');

      final refreshResponse = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = refreshResponse.data['data'] as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;
      await _storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

      // Retry original request
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(err.requestOptions);

      // Flush pending retries
      for (final retry in _pendingRetries) {
        retry();
      }
      _pendingRetries.clear();

      handler.resolve(retryResponse);
    } catch (_) {
      await _storage.clearTokens();
      _pendingRetries.clear();
      handler.reject(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

class _ApiLogInterceptor extends Interceptor {
  static const _line = '─────────────────────────────────────────────────────────';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri.toString();
    final query = options.queryParameters.isNotEmpty
        ? '\n│  Query   : ${options.queryParameters}'
        : '';
    final body = _fmt(options.data);
    final bodyLine = body.isNotEmpty ? '\n│  Body    :\n$body' : '';

    debugPrint(
      '[API] ┌$_line\n'
      '[API] │  ➤ REQUEST  [${options.method}]\n'
      '[API] │  URL     : $uri$query$bodyLine\n'
      '[API] └$_line',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final uri = response.requestOptions.uri.toString();
    final method = response.requestOptions.method;
    final status = response.statusCode;
    final body = _fmt(response.data);

    debugPrint(
      '[API] ┌$_line\n'
      '[API] │  ✓ RESPONSE [$method] $status\n'
      '[API] │  URL     : $uri\n'
      '[API] │  Body    :\n$body\n'
      '[API] └$_line',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = err.requestOptions.uri.toString();
    final method = err.requestOptions.method;
    final status = err.response?.statusCode ?? 'no response';
    final body = _fmt(err.response?.data);
    final bodyLine = body.isNotEmpty ? '\n│  Body    :\n$body' : '';

    debugPrint(
      '[API] ┌$_line\n'
      '[API] │  ✗ ERROR    [$method] $status\n'
      '[API] │  URL     : $uri\n'
      '[API] │  Message : ${err.message}$bodyLine\n'
      '[API] └$_line',
    );
    handler.next(err);
  }

  String _fmt(dynamic data) {
    if (data == null) return '';
    try {
      final encoded = const JsonEncoder.withIndent('   ').convert(data);
      return encoded.split('\n').map((l) => '│     $l').join('\n');
    } catch (_) {
      return '│     $data';
    }
  }
}
