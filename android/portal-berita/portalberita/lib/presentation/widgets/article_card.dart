import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/article_model.dart';
import '../../data/models/like_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/article_media_model.dart';

import '../../providers/auth_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/user_provider.dart';

import '../../data/services/article_media_service.dart';
import '../screens/article_create_screen.dart';

// Helper untuk membentuk URL foto profil
String? getProfilePictureUrl(String? filename) {
  if (filename == null || filename.isEmpty) return null;
  const baseUrl = 'http://10.0.2.2:8080/uploads/profile/';
  return '$baseUrl$filename';
}

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final likeProvider = Provider.of<LikeProvider>(context);
    final commentProvider = Provider.of<CommentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final user = authProvider.user;
    final token = authProvider.token;

    final likeList = likeProvider.likes(article.id);
    final commentList = commentProvider.comments(article.id);

    final isLiked = likeList.any((like) => like.userId == user?.id);
    final likeCount = likeList.length;
    final commentCount = commentList.length;

    final penulis = userProvider.getUserById(article.userId);

    return FutureBuilder<List<ArticleMedia>>(
      future:
          ArticleMediaService().fetchMediaByArticle(article.id, token ?? ''),
      builder: (context, snapshot) {
        String? imageUrl;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          imageUrl = snapshot.data!.first.mediaUrl;
          debugPrint('Article ${article.id} imageUrl: $imageUrl');
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Foto profil & username penulis
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: article.profilePicture != null
                            ? NetworkImage(
                                'http://10.0.2.2:8080/uploads/profile/${article.profilePicture}')
                            : const AssetImage('assets/images/ubsi.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          penulis?.username ?? article.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Titik tiga menu
                      Builder(
                        builder: (context) {
                          final user =
                              Provider.of<AuthProvider>(context, listen: false)
                                  .user;
                          final isAdmin = user?.role == 'admin';
                          final isOwner =
                              user != null && user.id == article.userId;
                          final canEditDelete = isAdmin || isOwner;
                          return PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit' && onEdit != null) onEdit!();
                              if (value == 'delete' && onDelete != null)
                                onDelete!();
                              if (value == 'save' && onSave != null) onSave!();
                            },
                            itemBuilder: (context) => [
                              if (canEditDelete)
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                              if (canEditDelete)
                                const PopupMenuItem(
                                    value: 'delete', child: Text('Hapus')),
                              const PopupMenuItem(
                                  value: 'save', child: Text('Simpan')),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gambar artikel jika ada
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio:
                          4 / 4, // Atau 4/3, atau sesuaikan sesuai kebutuhan
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl.startsWith('http')
                              ? imageUrl
                              : 'http://10.0.2.2:8080/$imageUrl',
                          fit: BoxFit
                              .cover, // Gambar akan selalu penuh, proporsional, tidak gepeng
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    size: 48, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    const SizedBox(height: 12),

                  // Judul artikel
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Konten artikel (potong jika panjang)
                  Text(
                    article.content.length > 180
                        ? '${article.content.substring(0, 180)}...'
                        : article.content,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Tanggal pembuatan
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        article.createdAt,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tombol Like dan Komentar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: token == null
                            ? null
                            : () async {
                                if (isLiked) {
                                  Like? like;
                                  try {
                                    like = likeList.firstWhere(
                                        (l) => l.userId == user?.id);
                                  } catch (_) {
                                    like = null;
                                  }
                                  if (like != null) {
                                    await likeProvider.removeLike(
                                        like.id, article.id, token);
                                    await likeProvider.loadLikes(
                                        article.id, token);
                                  }
                                } else {
                                  await likeProvider.addLike(
                                    {
                                      'user_id': user?.id,
                                      'article_id': article.id,
                                    },
                                    token,
                                  );
                                  await likeProvider.loadLikes(
                                      article.id, token);
                                }
                              },
                      ),
                      Text('$likeCount'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined,
                            color: Colors.grey),
                        onPressed: token == null
                            ? null
                            : () async {
                                await commentProvider.loadComments(
                                    article.id, token);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (_) =>
                                      CommentBottomSheet(articleId: article.id),
                                );
                              },
                      ),
                      Text('$commentCount'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- KOMENTAR BOTTOM SHEET -------------------

class CommentBottomSheet extends StatefulWidget {
  final int articleId;
  const CommentBottomSheet({super.key, required this.articleId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String? getProfilePictureUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    const baseUrl = 'http://10.0.2.2:8080/uploads/profile/';
    return '$baseUrl$filename';
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = Provider.of<CommentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final token = authProvider.token;
    final user = authProvider.user;

    final commentList = commentProvider.comments(widget.articleId);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Wrap(
        children: [
          const Center(
            child: Text(
              'Komentar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Komentar
          SizedBox(
            height: 280,
            child: commentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: commentList.length,
                    itemBuilder: (context, index) {
                      final comment = commentList[index];
                      final profilePic =
                          getProfilePictureUrl(comment.profilePicture);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePic != null
                              ? NetworkImage(profilePic)
                              : const AssetImage('assets/images/ubsi.png')
                                  as ImageProvider,
                        ),
                        title: Text(
                          comment.username ?? 'Pengguna',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(comment.comment),
                        trailing: user != null && comment.userId == user.id
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  if (token != null) {
                                    await commentProvider.removeComment(
                                      comment.id,
                                      widget.articleId,
                                      token,
                                    );
                                    await commentProvider.loadComments(
                                        widget.articleId, token);
                                    setState(() {});
                                  }
                                },
                              )
                            : null,
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Input komentar baru
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: token == null || controller.text.trim().isEmpty
                    ? null
                    : () async {
                        await commentProvider.addComment(
                          {
                            'article_id': widget.articleId,
                            'user_id': user?.id,
                            'comment': controller.text.trim(),
                          },
                          token!,
                        );
                        controller.clear();
                        await commentProvider.loadComments(
                            widget.articleId, token);
                        setState(() {});
                      },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
