import 'package:flutter/material.dart';
import '../data/models/like_model.dart';
import '../data/services/like_service.dart';

class LikeProvider extends ChangeNotifier {
  final LikeService _service = LikeService();
  final Map<int, List<Like>> _likesPerArticle = {};
  bool _isLoading = false;

  List<Like> likes(int articleId) => _likesPerArticle[articleId] ?? [];
  bool get isLoading => _isLoading;

  Future<void> loadLikes(int articleId, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final likes = await _service.fetchLikesByArticle(articleId, token);
      _likesPerArticle[articleId] = likes;
      debugPrint('[LIKE] Loaded likes for article $articleId: ${likes.length}');
      for (var like in likes) {
        debugPrint('[LIKE]   Like: id=${like.id}, userId=${like.userId}');
      }
    } catch (e) {
      debugPrint('[LIKE] Error loading likes for article $articleId: $e');
      _likesPerArticle[articleId] = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addLike(Map<String, dynamic> likeData, String token) async {
    debugPrint('[LIKE] Add like: $likeData');
    final result = await _service.addLike(likeData, token);
    debugPrint('[LIKE] Add like result: $result');
    return result;
  }

  Future<bool> removeLike(int likeId, int articleId, String token) async {
    debugPrint('[LIKE] Remove like: $likeId for article $articleId');
    final result = await _service.removeLike(likeId, token);
    debugPrint('[LIKE] Remove like result: $result');
    return result;
  }
}
