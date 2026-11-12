import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../models/api_models.dart';
import 'config.dart';
import 'navigation.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._()
    : _tokenStore = TokenStore(),
      _dio = Dio(
        BaseOptions(
          baseUrl: '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$apiPrefix/',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _tokenStore.readAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_shouldRefresh(error)) {
            if (error.response?.statusCode == 401 &&
                error.requestOptions.extra['authRetried'] == true) {
              await _expireSession();
            }
            handler.next(_dioError(error));
            return;
          }

          late final String accessToken;
          try {
            accessToken = await _refreshAccessToken();
          } on ApiException {
            await _expireSession();
            handler.next(_dioError(error));
            return;
          } on DioException {
            await _expireSession();
            handler.next(_dioError(error));
            return;
          } on FormatException {
            await _expireSession();
            handler.next(_dioError(error));
            return;
          } on PlatformException {
            await _expireSession();
            handler.next(_dioError(error));
            return;
          } on MissingPluginException {
            await _expireSession();
            handler.next(_dioError(error));
            return;
          }

          final request = error.requestOptions;
          request.extra['authRetried'] = true;
          request.headers['Authorization'] = 'Bearer $accessToken';
          try {
            handler.resolve(await _dio.fetch<dynamic>(request));
          } on DioException catch (retryError) {
            handler.next(_dioError(retryError));
          }
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final TokenStore _tokenStore;
  final Dio _dio;
  late final Dio _refreshDio;
  Future<String>? _refreshFuture;
  bool _loginRedirectScheduled = false;

  bool _shouldRefresh(DioException error) {
    final request = error.requestOptions;
    final path = request.path;
    return error.response?.statusCode == 401 &&
        request.extra['authRetried'] != true &&
        !_isPublicAuthPath(path);
  }

  bool _isPublicAuthPath(String path) {
    const publicAuthPaths = [
      'auth/login',
      'auth/register',
      'auth/refresh',
      'auth/password/forgot',
      'auth/password/reset',
      'auth/email/verify',
      'auth/email/resend-verification',
    ];
    return publicAuthPaths.any(path.endsWith);
  }

  Future<String> _refreshAccessToken() {
    final currentRefresh = _refreshFuture;
    if (currentRefresh != null) {
      return currentRefresh;
    }
    final refresh = _performRefresh();
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(
        'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
    }

    try {
      final response = await _refreshDio.post<Object?>(
        'auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final tokenPair = TokenPair.fromJson(_jsonMap(response.data));
      await _tokenStore.saveTokens(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        user: tokenPair.user,
      );
      return tokenPair.accessToken;
    } on DioException catch (error) {
      throw _apiError(error);
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz oturum yanıtı alındı.');
    }
  }

  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    late final Response<Object?> response;
    try {
      response = await _dio.post<Object?>(
        'auth/login',
        data: {'email': email, 'password': password},
      );
    } on DioException catch (error) {
      throw _apiError(error);
    }
    try {
      final tokenPair = TokenPair.fromJson(_jsonMap(response.data));
      await _tokenStore.saveTokens(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        user: tokenPair.user,
      );
      _loginRedirectScheduled = false;
      return tokenPair;
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz giriş yanıtı alındı.');
    } on PlatformException {
      throw const ApiException(
        'Oturum bilgileri güvenli şekilde kaydedilemedi.',
      );
    } on MissingPluginException {
      throw const ApiException('Güvenli oturum saklama kullanılamıyor.');
    }
  }

  Future<RegistrationResponse> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        'auth/register',
        data: {
          'email': email,
          'password': password,
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
        },
      );
      return RegistrationResponse.fromJson(_jsonMap(response.data));
    } on DioException catch (error) {
      throw _apiError(error);
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz kayıt yanıtı alındı.');
    }
  }

  Future<MessageResponse> verifyEmail({
    required String email,
    required String code,
  }) => _postAuthMessage('auth/email/verify', {'email': email, 'code': code});

  Future<MessageResponse> resendVerification({required String email}) =>
      _postAuthMessage('auth/email/resend-verification', {'email': email});

  Future<MessageResponse> requestPasswordReset({required String email}) =>
      _postAuthMessage('auth/password/forgot', {'email': email});

  Future<MessageResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _postAuthMessage('auth/password/reset', {
    'email': email,
    'code': code,
    'new_password': newPassword,
  });

  Future<MessageResponse> _postAuthMessage(
    String path,
    Map<String, Object?> data,
  ) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      return MessageResponse.fromJson(_jsonMap(response.data));
    } on DioException catch (error) {
      throw _apiError(error);
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz yanıt alındı.');
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _refreshDio.post<Object?>(
          'auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } on DioException catch (error) {
      throw _apiError(error);
    } finally {
      await _tokenStore.clear();
      _loginRedirectScheduled = false;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _jsonMap(response.data);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        rethrow;
      }
      throw _apiError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Sunucudan geçersiz liste yanıtı alındı.');
      }
      return data.map((item) => _jsonMap(item)).toList();
    } on DioException catch (error) {
      throw _apiError(error);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?>? data,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      return _jsonMap(response.data);
    } on DioException catch (error) {
      throw _apiError(error);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, Object?> data,
  }) async {
    try {
      final response = await _dio.patch<Object?>(path, data: data);
      return _jsonMap(response.data);
    } on DioException catch (error) {
      throw _apiError(error);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<Object?>(path);
    } on DioException catch (error) {
      throw _apiError(error);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required FormData data,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      return _jsonMap(response.data);
    } on DioException catch (error) {
      throw _apiError(error);
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    if (_loginRedirectScheduled) {
      return;
    }
    _loginRedirectScheduled = true;
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      loginRouteName,
      (_) => false,
    );
  }

  ApiException _apiError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(detail, statusCode: error.response?.statusCode);
      }
      if (detail is List) {
        final messages = detail
            .map((item) => item is Map ? item['msg'] : item)
            .where((item) => item != null)
            .join(' · ');
        if (messages.isNotEmpty) {
          return ApiException(messages, statusCode: error.response?.statusCode);
        }
      }
      if (detail != null) {
        return ApiException(
          detail.toString(),
          statusCode: error.response?.statusCode,
        );
      }
    }
    return ApiException(
      error.response?.statusCode == null
          ? 'Sunucuya bağlanılamadı. Bağlantınızı kontrol edip tekrar deneyin.'
          : 'İstek tamamlanamadı. Lütfen tekrar deneyin.',
      statusCode: error.response?.statusCode,
    );
  }

  DioException _dioError(DioException error) {
    final apiException = _apiError(error);
    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: error.error,
      message: apiException.message,
    );
  }

  Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const FormatException('Sunucudan geçersiz yanıt alındı.');
  }
}
