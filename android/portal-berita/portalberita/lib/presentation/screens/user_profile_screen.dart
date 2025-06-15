import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/comment_provider.dart';
import '../widgets/article_card.dart';
import '../../utils/helpers.dart' as helpers;
import 'edit_profile_screen.dart';
import 'article_create_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final articleProvider =
          Provider.of<ArticleProvider>(context, listen: false);
      final likeProvider = Provider.of<LikeProvider>(context, listen: false);
      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);

      final user = authProvider.user;
      final token = authProvider.token;

      if (user != null && token != null) {
        // Ambil semua artikel milik user
        final userArticles =
            articleProvider.articles.where((a) => a.userId == user.id).toList();
        // Load likes & comments untuk semua artikel user
        for (var article in userArticles) {
          await likeProvider.loadLikes(article.id, token);
          await commentProvider.loadComments(article.id, token);
        }
      }
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _goToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        // WAJIB: Refresh artikel agar username/foto profil penulis ikut update!
        await Provider.of<ArticleProvider>(context, listen: false)
            .loadArticles(token);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    print('USER PROFILE BUILD: ${user?.username}');

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    final articles = Provider.of<ArticleProvider>(context)
        .articles
        .where((a) => a.userId == user.id)
        .toList();

    final latestArticle = articles.isNotEmpty ? articles.first : null;
    final username = latestArticle?.username ?? user.username;
    final profilePicture = latestArticle?.profilePicture ?? user.profilePicture;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto profil
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      helpers.getProfilePictureUrl(profilePicture) != null
                          ? NetworkImage(
                              helpers.getProfilePictureUrl(profilePicture!)!)
                          : const AssetImage('assets/images/ubsi.png'),
                ),
                const SizedBox(width: 16),
                // Username, email, dan tombol edit profil
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Edit Profil',
                            onPressed: _goToEditProfile,
                          ),
                        ],
                      ),
                      Text(user.email),
                    ],
                  ),
                ),
                // Tombol Logout
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : articles.isEmpty
                    ? const Center(
                        child: Text('Belum ada artikel yang dibuat.'))
                    : ListView.builder(
                        itemCount: articles.length,
                        itemBuilder: (context, index) {
                          final article = articles[index];
                          return ArticleCard(
                            article: article,
                            onEdit: () async {
                              debugPrint('[USER_PROFILE] Edit article id: ${article.id}');
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArticleCreateScreen(article: article),
                                ),
                              );
                              debugPrint('[USER_PROFILE] Edit result: $result');
                              if (result == true) {
                                final token = Provider.of<AuthProvider>(context, listen: false).token;
                                if (token != null) {
                                  await Provider.of<ArticleProvider>(context, listen: false).loadArticles(token);
                                  setState(() {});
                                  debugPrint('[USER_PROFILE] Artikel berhasil diupdate dan di-refresh');
                                }
                              }
                            },
                            onDelete: () async {
                              final token = Provider.of<AuthProvider>(context,
                                      listen: false)
                                  .token;
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content: Text(
                                      'Yakin ingin menghapus artikel "${article.title}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus')),
                                  ],
                                ),
                              );
                              if (confirmed == true && token != null) {
                                final success = await Provider.of<ArticleProvider>(context, listen: false)
                                    .deleteArticle(article.id, token);
                                if (success) {
                                  await Provider.of<ArticleProvider>(context,
                                          listen: false)
                                      .loadArticles(token);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Artikel dihapus'),
                                        backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Gagal menghapus artikel'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            onSave: () {
                              // Implementasi simpan artikel (misal: tambahkan ke daftar favorit user)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Artikel disimpan!')),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
