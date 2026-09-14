import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../models/call_model.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

/// Local storage helper wrapping SharedPreferences
class StorageService {
  StorageService._();
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> saveCurrentUser(UserModel user) async {
    await _prefs!.setString(AppConstants.keyCurrentUser, user.toJsonString());
    await _prefs!.setBool(AppConstants.keyIsLoggedIn, true);
  }

  UserModel? getCurrentUser() {
    final json = _prefs!.getString(AppConstants.keyCurrentUser);
    if (json == null) return null;
    try {
      return UserModel.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    await _prefs!.remove(AppConstants.keyCurrentUser);
    await _prefs!.setBool(AppConstants.keyIsLoggedIn, false);
  }

  bool get isLoggedIn => _prefs!.getBool(AppConstants.keyIsLoggedIn) ?? false;

  // ── Call History ──────────────────────────────────────────────────────────

  static const _keyCallHistory = 'call_history';

  Future<void> saveCallHistory(List<CallModel> calls) async {
    final list = calls.map((c) => c.toJson()).toList();
    await _prefs!.setString(_keyCallHistory, jsonEncode(list));
  }

  List<CallModel> getCallHistory() {
    final json = _prefs!.getString(_keyCallHistory);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CallModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addCallToHistory(CallModel call) async {
    final history = getCallHistory();
    history.insert(0, call);
    // Keep only last 100 calls
    if (history.length > 100) history.removeRange(100, history.length);
    await saveCallHistory(history);
  }

  // ── Mock Users ────────────────────────────────────────────────────────────

  static const _keyMockUsers = 'mock_users';

  Future<void> saveMockUsers(List<UserModel> users) async {
    final list = users.map((u) => u.toJson()).toList();
    await _prefs!.setString(_keyMockUsers, jsonEncode(list));
  }

  List<UserModel> getMockUsers() {
    final json = _prefs!.getString(_keyMockUsers);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs!.setString(AppConstants.keyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final name = _prefs!.getString(AppConstants.keyThemeMode);
    return ThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
