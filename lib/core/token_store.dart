import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/api_models.dart';

class TokenStore {
  static const _accessTokenKey = 'study_friend.access_token';
  static const _refreshTokenKey = 'study_friend.refresh_token';
  static const _userKey = 'study_friend.user';

  final FlutterSecureStorage _storage;

  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<UserPublic?> readUser() async {
    final value = await _storage.read(key: _userKey);
    if (value == null) {
      return null;
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Saklanan kullanıcı bilgisi geçersiz.');
    }
    return UserPublic.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required UserPublic user,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } on PlatformException {
      await clear();
      rethrow;
    } on MissingPluginException {
      await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  Future<bool> hasTokens() async {
    final accessToken = await readAccessToken();
    final refreshToken = await readRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }
}
