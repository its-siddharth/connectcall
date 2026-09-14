import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/zego_service.dart';
import '../core/utils/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // A global key so ZegoService can get a BuildContext for init
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  AuthState get state => _state;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Future<void> init(StorageService storage) async {
    await AuthService.instance.init(storage);
    if (AuthService.instance.isLoggedIn) {
      _currentUser = AuthService.instance.currentUser;
      _state = AuthState.authenticated;
      // Re-initialise Zego if the user was already logged in (app restart)
      _initZego(_currentUser!);
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.instance.login(email, password);
    if (result.isSuccess) {
      _currentUser = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      _initZego(_currentUser!);
      return true;
    } else {
      _errorMessage = result.error;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.instance.register(
      name: name,
      email: email,
      password: password,
    );
    if (result.isSuccess) {
      _currentUser = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      _initZego(_currentUser!);
      return true;
    } else {
      _errorMessage = result.error;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ZegoService.instance.uninit();
    await AuthService.instance.logout();
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? avatarUrl}) async {
    final userId = _currentUser?.id;
    if (userId == null) return false;

    final result = await AuthService.instance.updateProfile(
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
    );
    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _initZego(UserModel user) {
    if (!ZegoService.isConfigured) return;
    // Get a context from the navigator key to init Zego
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ZegoService.instance.init(user: user, context: ctx);
    } else {
      // Context not ready yet (app cold-start) — retry after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx2 = navigatorKey.currentContext;
        if (ctx2 != null) {
          ZegoService.instance.init(user: user, context: ctx2);
        }
      });
    }
  }
}
