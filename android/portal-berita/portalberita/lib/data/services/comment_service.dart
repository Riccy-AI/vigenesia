import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';

class CommentService {
  static const String _baseUrl = "http://10.0.2.2:8080/api/comments";

  // Ambil komentar by article id
  Future<List<Comment>> fetchCommentsByArticle(
      int articleId, String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/$articleId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  // Tambah komentar
  Future<bool> addComment(
      Map<String, dynamic> commentData, String token) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/add"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(commentData),
    );
    return response.statusCode == 201;
  }

  // Hapus komentar
  Future<bool> removeComment(int id, String token) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/remove/$id"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
