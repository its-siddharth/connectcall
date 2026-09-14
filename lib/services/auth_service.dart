import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../core/utils/storage_service.dart';

/// Mock authentication service — simulates a real backend.
/// In a production app, replace with Firebase Auth / Supabase.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _uuid = Uuid();

  StorageService? _storage;

  Future<void> init(StorageService storage) async {
    _storage = storage;
    await _seedMockUsers();
  }

  StorageService get _store {
    assert(_storage != null, 'AuthService not initialized');
    return _storage!;
  }

  // ── Mock user database ────────────────────────────────────────────────────

  static final List<Map<String, String>> _mockCredentials = [
    {'id': 'user_1', 'email': 'alice@example.com', 'password': 'password123', 'name': 'Alice Johnson'},
    {'id': 'user_2', 'email': 'bob@example.com', 'password': 'password123', 'name': 'Bob Smith'},
    {'id': 'user_3', 'email': 'carol@example.com', 'password': 'password123', 'name': 'Carol Davis'},
    {'id': 'user_4', 'email': 'david@example.com', 'password': 'password123', 'name': 'David Wilson'},
    {'id': 'user_5', 'email': 'eva@example.com', 'password': 'password123', 'name': 'Eva Martinez'},
    {'id': 'user_6', 'email': 'frank@example.com', 'password': 'password123', 'name': 'Frank Brown'},
    {'id': 'user_7', 'email': 'grace@example.com', 'password': 'password123', 'name': 'Grace Lee'},
    {'id': 'user_8', 'email': 'henry@example.com', 'password': 'password123', 'name': 'Henry Taylor'},
  ];

  Future<void> _seedMockUsers() async {
    final existing = _store.getMockUsers();
    if (existing.isNotEmpty) return;

    final users = _mockCredentials.map((cred) {
      return UserModel(
        id: cred['id']!,
        name: cred['name']!,
        email: cred['email']!,
        status: UserStatus.offline,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastSeen: DateTime.now().subtract(Duration(hours: cred['id']!.hashCode % 24)),
      );
    }).toList();

    await _store.saveMockUsers(users);
  }

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Returns the logged-in user or null
  UserModel? get currentUser => _store.getCurrentUser();
  bool get isLoggedIn => _store.isLoggedIn;

  /// Login with email/password
  Future<AuthResult> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final trimmedEmail = email.trim().toLowerCase();

    // Check mock credentials
    final cred = _mockCredentials.firstWhere(
      (c) => c['email'] == trimmedEmail && c['password'] == password,
      orElse: () => {},
    );

    if (cred.isEmpty) {
      return AuthResult.failure('Invalid email or password.');
    }

    final allUsers = _store.getMockUsers();
    var user = allUsers.firstWhere(
      (u) => u.id == cred['id'],
      orElse: () => UserModel(
        id: cred['id']!,
        name: cred['name']!,
        email: cred['email']!,
        createdAt: DateTime.now(),
      ),
    );

    // Mark user as online
    user = user.copyWith(status: UserStatus.online);
    final updatedUsers = allUsers
        .map((u) => u.id == user.id ? user : u)
        .toList();
    await _store.saveMockUsers(updatedUsers);
    await _store.saveCurrentUser(user);

    return AuthResult.success(user);
  }

  /// Register new account
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final trimmedEmail = email.trim().toLowerCase();

    // Check if email already exists
    final existingCred = _mockCredentials.firstWhere(
      (c) => c['email'] == trimmedEmail,
      orElse: () => {},
    );
    if (existingCred.isNotEmpty) {
      return AuthResult.failure('An account with this email already exists.');
    }

    final userId = _uuid.v4();
    final newUser = UserModel(
      id: userId,
      name: name.trim(),
      email: trimmedEmail,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );

    // Add to mock credentials in memory
    _mockCredentials.add({
      'id': userId,
      'email': trimmedEmail,
      'password': password,
      'name': name.trim(),
    });

    // Save user to storage
    final allUsers = _store.getMockUsers();
    allUsers.add(newUser);
    await _store.saveMockUsers(allUsers);
    await _store.saveCurrentUser(newUser);

    return AuthResult.success(newUser);
  }

  /// Logout
  Future<void> logout() async {
    final user = currentUser;
    if (user != null) {
      // Mark as offline
      final allUsers = _store.getMockUsers();
      final updated = allUsers
          .map((u) => u.id == user.id
              ? u.copyWith(
                  status: UserStatus.offline,
                  lastSeen: DateTime.now(),
                )
              : u)
          .toList();
      await _store.saveMockUsers(updated);
    }
    await _store.clearCurrentUser();
  }

  /// Update profile
  Future<AuthResult> updateProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final allUsers = _store.getMockUsers();
    final idx = allUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return AuthResult.failure('User not found.');

    final updated = allUsers[idx].copyWith(
      name: name,
      avatarUrl: avatarUrl,
    );
    allUsers[idx] = updated;
    await _store.saveMockUsers(allUsers);
    await _store.saveCurrentUser(updated);

    return AuthResult.success(updated);
  }
}

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;

  const AuthResult._({required this.isSuccess, this.user, this.error});

  factory AuthResult.success(UserModel user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, error: error);
}
