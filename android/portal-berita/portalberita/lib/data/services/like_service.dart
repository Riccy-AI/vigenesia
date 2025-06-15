import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/like_model.dart';

class LikeService {
  static const String _baseUrl = "http://10.0.2.2:8080/api/likes";

  // Tambah like
  Future<bool> addLike(Map<String, dynamic> likeData, String token) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/add"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(likeData),
    );
    print('[LIKE] Add like response: ${response.statusCode} ${response.body}');
    return response.statusCode == 201;
  }

  // Hapus like
  Future<bool> removeLike(int id, String token) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/remove/$id"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // Ambil likes by article id
  Future<List<Like>> fetchLikesByArticle(int articleId, String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/article/$articleId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    print(
        '[LIKE] Fetch likes response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((json) => Like.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load likes');
    }
  }
}
