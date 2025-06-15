import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import '../models/article_media_model.dart';
import '../models/comment_model.dart';
import '../models/like_model.dart';

class ArticleService {
  static const String _baseUrl = "http://10.0.2.2:8080/api/articles";

  // Ambil semua artikel
  Future<List<Article>> fetchArticles(String token) async {
    print('TOKEN USED: $token'); // Tambahkan di sini
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('FETCH ARTICLES RESPONSE: ${response.body}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded.containsKey('data') &&
          decoded['data'] is List) {
        final List data = decoded['data'];
        return data.map((json) => Article.fromJson(json)).toList();
      } else {
        print('FETCH ARTICLES RESPONSE (unexpected): $decoded');
        return [];
      }
    } else {
      print('FETCH ARTICLES RESPONSE: ${response.body}');
      throw Exception('Failed to load articles');
    }
  }

  // Ambil artikel by id
  Future<Article> fetchArticleById(int id, String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/$id"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return Article.fromJson(data);
    } else {
      throw Exception('Failed to load article');
    }
  }

  // Buat artikel baru
  Future<int?> createArticle(
      Map<String, dynamic> articleData, String token) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/create"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(articleData),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Pastikan data['data']['id'] adalah int, jika perlu parse ke int
      final id = data['data']?['id'];
      if (id != null) {
        return int.tryParse(id.toString());
      }
    }
    return null;
  }

  // Update artikel
  Future<bool> updateArticle(
      int id, Map<String, dynamic> articleData, String? token) async {
    debugPrint(
        '[SERVICE] updateArticle called with id: $id, data: $articleData');
    final response = await http.put(
      Uri.parse("$_baseUrl/update/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(articleData),
    );
    debugPrint(
        '[SERVICE] updateArticle response: ${response.statusCode} ${response.body}');
    return response.statusCode == 200;
  }

  // Hapus artikel
  Future<bool> deleteArticle(int id, String token) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/delete/$id"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
