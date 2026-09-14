import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<UserModel> get users => _users;
  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadUsers({String? excludeId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await UserService.instance.getUsersWithLiveStatus(
        excludeId: excludeId,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load contacts. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query, {String? excludeId}) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await UserService.instance.searchUsers(
        query,
        excludeId: excludeId,
      );
    } catch (e) {
      _searchResults = [];
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  UserModel? getUserById(String id) => UserService.instance.getUserById(id);
}
