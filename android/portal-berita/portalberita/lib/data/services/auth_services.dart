import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:8080/api";

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['token']);
      await prefs.setString('refresh_token', data['refresh_token']);
      await prefs.setString('user', jsonEncode(data['user']));

      return {
        'success': true,
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
        'refresh_token': data['refresh_token'],
      };
    } else {
      return {'success': false, 'message': 'Login gagal'};
    }
  }

  // Register
  Future<bool> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return response.statusCode == 201;
  }

  // Get data user dari API (dengan auto-refresh jika token expired)
  Future<UserModel?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse("$_baseUrl/me"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else if (response.statusCode == 401) {
      final body = jsonDecode(response.body);
      if (body['message'] == 'Token expired') {
        final refreshed = await refreshAccessToken();
        if (refreshed['success']) {
          token = refreshed['token'];
          final retryResponse = await http.get(
            Uri.parse("$_baseUrl/me"),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return UserModel.fromJson(data);
          }
        }
      }
    }

    return null;
  }

  // Update profil user (tanpa foto)
  Future<bool> updateProfile(Map<String, dynamic> data, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return false;

    final userData = jsonDecode(userString);
    final userId = userData['id'];

    final response = await http.put(
      Uri.parse("$_baseUrl/users/update/$userId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  // Upload foto profil (multipart)
  Future<bool> uploadProfilePicture(File file, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return false;

    final userData = jsonDecode(userString);
    final userId = userData['id'];

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$_baseUrl/users/upload-profile-picture/$userId"),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files
        .add(await http.MultipartFile.fromPath('profile_picture', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Update cache user
      userData['profile_picture'] = result['profile_picture'];
      await prefs.setString('user', jsonEncode(userData));
      return true;
    }

    return false;
  }

  // ✅ Refresh access token dan kembalikan format Map
  Future<Map<String, dynamic>> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    final response = await http.post(
      Uri.parse("$_baseUrl/token/refresh"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('access_token', data['access_token']);
      return {
        'success': true,
        'token': data['access_token'],
      };
    }

    return {'success': false};
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  // Ambil cache user dari lokal
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = jsonDecode(userString);
      return UserModel.fromJson(userData);
    }
    return null;
  }
}
