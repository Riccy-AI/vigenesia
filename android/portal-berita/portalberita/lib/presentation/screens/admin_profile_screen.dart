import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/article_card.dart';
import '../../utils/helpers.dart' as helpers;
import 'edit_profile_screen.dart';
import 'article_create_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        await Provider.of<ArticleProvider>(context, listen: false)
            .loadArticles(token);
        await Provider.of<UserProvider>(context, listen: false).loadAllUsers();
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
        await Provider.of<ArticleProvider>(context, listen: false)
            .loadArticles(token);
        await Provider.of<UserProvider>(context, listen: false).loadAllUsers();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final articles = Provider.of<ArticleProvider>(context).articles;
    final users = Provider.of<UserProvider>(context).users;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    // Ambil data header dari artikel terbaru milik admin (opsional)
    final adminArticles = articles.where((a) => a.userId == user.id).toList();
    final latestArticle = adminArticles.isNotEmpty ? adminArticles.first : null;
    final username = latestArticle?.username ?? user.username;
    final profilePicture = latestArticle?.profilePicture ?? user.profilePicture;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header admin
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage:
                              helpers.getProfilePictureUrl(profilePicture) !=
                                      null
                                  ? NetworkImage(helpers
                                      .getProfilePictureUrl(profilePicture!)!)
                                  : const AssetImage('assets/images/ubsi.png'),
                        ),
                        const SizedBox(width: 16),
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
                                          fontWeight: FontWeight.bold),
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
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', (route) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Menu: List Semua Artikel
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('List Semua Artikel'),
                    onTap: () async {
                      final token =
                          Provider.of<AuthProvider>(context, listen: false)
                              .token;
                      await Provider.of<ArticleProvider>(context, listen: false)
                          .loadArticles(token!);
                      if (!mounted) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SizedBox(
                          height: 600,
                          child: ListView.builder(
                            itemCount: articles.length,
                            itemBuilder: (context, index) {
                              final article = articles[index];
                              return ArticleCard(
                                article: article,
                                onEdit: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ArticleCreateScreen(article: article),
                                    ),
                                  );
                                  if (result == true) {
                                    final token = Provider.of<AuthProvider>(
                                            context,
                                            listen: false)
                                        .token;
                                    if (token != null) {
                                      await Provider.of<ArticleProvider>(
                                              context,
                                              listen: false)
                                          .loadArticles(token);
                                      setState(() {});
                                    }
                                    Navigator.pop(
                                        context); // Tutup bottom sheet setelah edit
                                  }
                                },
                                onDelete: () async {
                                  final token = Provider.of<AuthProvider>(
                                          context,
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
                                    final success =
                                        await Provider.of<ArticleProvider>(
                                                context,
                                                listen: false)
                                            .deleteArticle(article.id, token);
                                    if (success) {
                                      await Provider.of<ArticleProvider>(
                                              context,
                                              listen: false)
                                          .loadArticles(token);
                                      setState(() {});
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Artikel dihapus'),
                                            backgroundColor: Colors.green),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Gagal menghapus artikel'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                    Navigator.pop(
                                        context); // Tutup bottom sheet setelah delete
                                  }
                                },
                                onSave: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Artikel disimpan!')),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // Menu: List Semua User
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('List Semua User'),
                    onTap: () async {
                      final token =
                          Provider.of<AuthProvider>(context, listen: false)
                              .token;
                      await Provider.of<UserProvider>(context, listen: false)
                          .loadAllUsers();
                      if (!mounted) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SizedBox(
                          height: 400,
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              final users = userProvider.users;
                              if (userProvider.isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (users.isEmpty) {
                                return const Center(
                                    child: Text('Tidak ada user.'));
                              }
                              return ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final u = users[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          (u.profilePicture != null &&
                                                  u.profilePicture!.isNotEmpty)
                                              ? NetworkImage(
                                                  u.profilePicture!
                                                          .startsWith('http')
                                                      ? u.profilePicture!
                                                      : 'http://10.0.2.2:8080/uploads/profile/${u.profilePicture!}',
                                                )
                                              : const AssetImage(
                                                      'assets/images/ubsi.png')
                                                  as ImageProvider,
                                    ),
                                    title: Text(u.username),
                                    subtitle: Text(u.email),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          final token =
                                              Provider.of<AuthProvider>(context,
                                                      listen: false)
                                                  .token;
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Konfirmasi'),
                                              content: Text(
                                                  'Yakin ingin menghapus user ${u.username}?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text('Batal')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: const Text('Hapus')),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true &&
                                              token != null) {
                                            final success =
                                                await Provider.of<UserProvider>(
                                                        context,
                                                        listen: false)
                                                    .deleteUser(u.id, token);
                                            if (success) {
                                              await Provider.of<UserProvider>(
                                                      context,
                                                      listen: false)
                                                  .loadAllUsers();
                                              setState(() {});
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('User dihapus'),
                                                    backgroundColor:
                                                        Colors.green),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Gagal menghapus user'),
                                                    backgroundColor:
                                                        Colors.red),
                                              );
                                            }
                                            Navigator.pop(
                                                context); // Tutup bottom sheet setelah delete
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus User')),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // Menu: Daftarkan Admin Baru
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Daftarkan Admin Baru'),
                    onTap: () {
                      Navigator.pushNamed(context, '/register',
                          arguments: {'role': 'admin'});
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
