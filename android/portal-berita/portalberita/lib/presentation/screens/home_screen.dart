import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/comment_provider.dart';
import '../widgets/article_card.dart';
import 'article_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        await Provider.of<ArticleProvider>(context, listen: false)
            .loadArticles(token);
        final articles =
            Provider.of<ArticleProvider>(context, listen: false).articles;
        final likeProvider = Provider.of<LikeProvider>(context, listen: false);
        final commentProvider =
            Provider.of<CommentProvider>(context, listen: false);
        for (var article in articles) {
          await likeProvider.loadLikes(article.id, token);
          await commentProvider.loadComments(article.id, token);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil user dari Provider, bukan dari argumen!
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Vigenesia Portal Berita',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: Consumer<ArticleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.articles.isEmpty) {
            return const Center(child: Text('Belum ada artikel.'));
          }
          final sortedArticles = [...provider.articles]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            itemCount: sortedArticles.length,
            itemBuilder: (context, index) {
              final article = sortedArticles[index];
              return ArticleCard(
                article: article,
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleCreateScreen(article: article),
                    ),
                  );
                  if (result == true) {
                    final token =
                        Provider.of<AuthProvider>(context, listen: false).token;
                    if (token != null) {
                      await Provider.of<ArticleProvider>(context, listen: false)
                          .loadArticles(token);
                      setState(() {});
                    }
                  }
                },
                onDelete: () async {
                  final token =
                      Provider.of<AuthProvider>(context, listen: false).token;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: Text(
                          'Yakin ingin menghapus artikel "${article.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus')),
                      ],
                    ),
                  );
                  if (confirmed == true && token != null) {
                    final success = await Provider.of<ArticleProvider>(context,
                            listen: false)
                        .deleteArticle(article.id, token);
                    if (success) {
                      await Provider.of<ArticleProvider>(context, listen: false)
                          .loadArticles(token);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Artikel dihapus'),
                            backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Gagal menghapus artikel'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                onSave: () {
                  // Implementasi simpan artikel (misal: tambahkan ke daftar favorit user)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Artikel disimpan!')),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.home_rounded,
                  size: 28,
                  color:
                      _selectedIndex == 0 ? Colors.blue[800] : Colors.grey[500],
                ),
                tooltip: 'Home',
                onPressed: () {
                  setState(() => _selectedIndex = 0);
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.person_rounded,
                  size: 28,
                  color:
                      _selectedIndex == 2 ? Colors.blue[800] : Colors.grey[500],
                ),
                tooltip: 'Profile',
                onPressed: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buat Artikel',
        backgroundColor: Colors.blue[800],
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/article-create',
          );
          if (result == true) {
            final token =
                Provider.of<AuthProvider>(context, listen: false).token;
            if (token != null) {
              Provider.of<ArticleProvider>(context, listen: false)
                  .loadArticles(token);
            }
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
