import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  String? _token;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && token != null;

  Future<bool> login(String email, String password) async {
    final result = await _authService.login(email, password);
    if (result['success']) {
      _user = result['user'];
      // Ambil token dari response login, BUKAN dari SharedPreferences
      _token = result['token'];
      // Simpan token ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    return await _authService.register(username, email, password);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return false;
    final result = await _authService.updateProfile(data, _token!);
    if (result) {
      // Refresh user data
      await checkLogin();
    }
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> checkLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      _user = await _authService.getCachedUser();
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
      notifyListeners();
    }
  }

  Future<void> refreshToken() async {
    await _authService.refreshAccessToken();
    // Update token setelah refresh
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    notifyListeners();
  }

  Future<void> refreshUserProfile() async {
    final userId = user?.id;
    final token = this.token;
    if (userId == null || token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/users/profile/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = UserModel.fromJson(data['data'] ?? data);

      // Tambahkan baris ini untuk update cache user di SharedPreferences!
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode((_user!).toJson()));

      notifyListeners();
    }
  }
}
