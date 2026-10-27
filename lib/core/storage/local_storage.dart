import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voxora/data/models/user_model.dart';

class LocalStorage {
  // ── Secure storage (tokens) ───────────────────────
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── SharedPreferences (non-sensitive data) ────────
  // Lazily obtained; call [_prefs] everywhere.
  SharedPreferences? _prefsInstance;

  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  // ── Key constants ─────────────────────────────────
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';
  static const String _keyOnboardingDone = 'onboarding_complete';
  static const String _keySelectedLevel = 'selected_level';
  static const String _keyThemeMode = 'theme_mode';

  // ── Token ─────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _secure.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return _secure.read(key: _keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secure.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _secure.read(key: _keyRefreshToken);
  }

  Future<void> clearToken() async {
    await _secure.delete(key: _keyAuthToken);
    await _secure.delete(key: _keyRefreshToken);
  }

  // ── User ──────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await _prefs;
    await prefs.remove(_keyUser);
  }

  // ── Onboarding ────────────────────────────────────

  Future<void> setOnboardingComplete() async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  // ── Level ─────────────────────────────────────────

  Future<void> saveSelectedLevel(String level) async {
    final prefs = await _prefs;
    await prefs.setString(_keySelectedLevel, level);
  }

  Future<String?> getSelectedLevel() async {
    final prefs = await _prefs;
    return prefs.getString(_keySelectedLevel);
  }

  // ── Theme ─────────────────────────────────────────

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode);
  }

  // ── Clear all ─────────────────────────────────────

  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
    final prefs = await _prefs;
    // Preserve theme preference when clearing auth data
    final theme = prefs.getString(_keyThemeMode);
    await prefs.clear();
    if (theme != null) {
      await prefs.setString(_keyThemeMode, theme);
    }
  }
}
