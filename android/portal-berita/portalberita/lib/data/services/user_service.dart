import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  static const String _baseUrl = "http://10.0.2.2:8080/api";

  // Ambil semua user (hanya untuk admin, pastikan endpoint tersedia)
  Future<List<UserModel>> fetchSimpleUsers() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/users/simple"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List users = data['data'] ?? [];
      return users.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<UserModel?> fetchSimpleUserById(int userId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/users/simple/$userId"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['data']);
    }
    return null;
  }

  Future<bool> deleteUser(int userId, String token) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/api/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
