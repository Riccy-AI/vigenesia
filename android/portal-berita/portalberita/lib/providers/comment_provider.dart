import 'package:flutter/material.dart';
import '../data/models/comment_model.dart';
import '../data/services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _service = CommentService();
  final Map<int, List<Comment>> _commentsPerArticle = {};
  bool _isLoading = false;

  List<Comment> comments(int articleId) => _commentsPerArticle[articleId] ?? [];
  bool get isLoading => _isLoading;

  Future<void> loadComments(int articleId, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final comments = await _service.fetchCommentsByArticle(articleId, token);
      _commentsPerArticle[articleId] = comments;
      debugPrint(
          '[COMMENT] Loaded comments for article $articleId: ${comments.length}');
      for (var comment in comments) {
        debugPrint(
            '[COMMENT]   Comment: id=${comment.id}, userId=${comment.userId}, text=${comment.comment}');
      }
    } catch (e) {
      debugPrint('[COMMENT] Error loading comments for article $articleId: $e');
      _commentsPerArticle[articleId] = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addComment(
      Map<String, dynamic> commentData, String token) async {
    debugPrint('[COMMENT] Add comment: $commentData');
    final result = await _service.addComment(commentData, token);
    debugPrint('[COMMENT] Add comment result: $result');
    return result;
  }

  Future<bool> removeComment(int id, int articleId, String token) async {
    debugPrint('[COMMENT] Remove comment: $id for article $articleId');
    final result = await _service.removeComment(id, token);
    debugPrint('[COMMENT] Remove comment result: $result');
    return result;
  }
}
