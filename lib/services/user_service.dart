import '../models/user_model.dart';
import '../core/utils/storage_service.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  StorageService? _storage;

  void init(StorageService storage) {
    _storage = storage;
  }

  StorageService get _store {
    assert(_storage != null, 'UserService not initialized');
    return _storage!;
  }

  /// Returns all users except the current user
  Future<List<UserModel>> getUsers({String? excludeId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final all = _store.getMockUsers();
    if (excludeId != null) {
      return all.where((u) => u.id != excludeId).toList();
    }
    return all;
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query, {String? excludeId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getUsers(excludeId: excludeId);

    final all = _store.getMockUsers();
    return all.where((u) {
      if (excludeId != null && u.id == excludeId) return false;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  /// Get a single user by id
  UserModel? getUserById(String id) {
    final all = _store.getMockUsers();
    try {
      return all.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Simulate online/offline status changes for demo purposes
  Future<List<UserModel>> getUsersWithLiveStatus({String? excludeId}) async {
    final users = await getUsers(excludeId: excludeId);
    // Randomise status a bit for demo – not changing storage
    return users.asMap().entries.map((entry) {
      final statuses = [UserStatus.online, UserStatus.online, UserStatus.offline];
      return entry.value.copyWith(status: statuses[entry.key % statuses.length]);
    }).toList();
  }
}
