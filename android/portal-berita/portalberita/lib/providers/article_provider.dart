import 'package:flutter/material.dart';
import '../data/models/article_model.dart';
import '../data/services/article_service.dart';

class ArticleProvider extends ChangeNotifier {
  final ArticleService _service = ArticleService();
  List<Article> _articles = [];
  bool _isLoading = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;

  Future<void> loadArticles(String token) async {
    print('LOAD ARTICLES CALLED WITH TOKEN: $token');
    _isLoading = true;
    notifyListeners();
    try {
      _articles = await _service.fetchArticles(token);
    } catch (e) {
      print('ERROR LOAD ARTICLES: $e');
      _articles = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteArticle(int articleId, String token) async {
    final result = await _service.deleteArticle(articleId, token);
    if (result) {
      await loadArticles(token);
      notifyListeners();
    }
    return result;
  }
}
