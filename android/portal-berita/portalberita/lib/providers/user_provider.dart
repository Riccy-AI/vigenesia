import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();
  final Map<int, UserModel> _userMap = {};
  bool _isLoading = false;
  List<UserModel> get users => _userMap.values.toList();

  bool get isLoading => _isLoading;

  UserModel? getUserById(int userId) => _userMap[userId];
  String? getUsername(int userId) => _userMap[userId]?.username;

  String? getProfilePictureByUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url.startsWith("http") ? url : "http://10.0.2.2:8080/$url";
  }

  String? getProfilePicture(int userId) {
    final user = _userMap[userId];
    if (user != null &&
        user.profilePicture != null &&
        user.profilePicture!.isNotEmpty) {
      return user.profilePicture;
    } else {
      return null; // artinya gunakan AssetImage sebagai fallback
    }
  }

  // Panggil ini saat aplikasi mulai atau setelah login
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final users = await _service.fetchSimpleUsers();
      _userMap.clear();
      for (var user in users) {
        _userMap[user.id] = user;
      }
    } catch (e) {
      print('ERROR LOAD USERS: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<UserModel?> fetchSimpleUserById(int userId,
      {bool reload = false}) async {
    if (!reload && _userMap.containsKey(userId)) {
      return _userMap[userId];
    }

    try {
      final user = await _service.fetchSimpleUserById(userId);
      if (user != null) {
        _userMap[user.id] = user;
        notifyListeners();
      }
      return user;
    } catch (e) {
      print('ERROR FETCH USER $userId: $e');
      return null;
    }
  }

  Future<bool> deleteUser(int userId, String token) async {
    try {
      final result = await _service.deleteUser(userId, token);
      if (result) {
        _userMap.remove(userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('ERROR DELETE USER $userId: $e');
      return false;
    }
  }
}
