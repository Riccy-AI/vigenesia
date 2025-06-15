import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/article_service.dart';
import '../../data/services/article_media_service.dart';
import '../../data/services/auth_services.dart';
import '../../data/models/article_model.dart';

class ArticleCreateScreen extends StatefulWidget {
  final Article? article; // Tambahkan ini

  const ArticleCreateScreen({super.key, this.article});

  @override
  State<ArticleCreateScreen> createState() => _ArticleCreateScreenState();
}

class _ArticleCreateScreenState extends State<ArticleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  File? _selectedImage;
  bool _isLoading = false;
  String? _oldImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController =
        TextEditingController(text: widget.article?.content ?? '');

    if (widget.article != null) {
      _loadOldImage();
    }
  }

  Future<void> _loadOldImage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final mediaList = await ArticleMediaService()
        .fetchMediaByArticle(widget.article!.id, token);
    if (mediaList.isNotEmpty) {
      setState(() {
        _oldImageUrl = mediaList.first.mediaUrl;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token =
          (await SharedPreferences.getInstance()).getString('access_token');
      final user = await AuthService().getCachedUser();

      if (token == null || user == null) {
        throw Exception('User belum login');
      }

      if (widget.article == null) {
        // CREATE MODE
        final articleData = {
          'user_id': user.id,
          'title': _titleController.text,
          'content': _contentController.text,
        };
        final articleId =
            await ArticleService().createArticle(articleData, token);

        // ✅ Upload gambar ke ArticleMedia jika ada
        if (_selectedImage != null && articleId != null) {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://10.0.2.2:8080/api/media/create'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.fields['article_id'] = articleId.toString();
          request.fields['media_type'] = 'image';
          request.files.add(
              await http.MultipartFile.fromPath('media', _selectedImage!.path));
          final response = await request.send();
          debugPrint('[MEDIA] Upload response: ${response.statusCode}');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artikel berhasil dibuat!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // EDIT MODE
        final articleData = {
          'title': _titleController.text,
          'content': _contentController.text,
        };
        debugPrint('[EDIT] Update Article ID: ${widget.article!.id}');
        debugPrint('[EDIT] Data: $articleData');
        final success = await ArticleService()
            .updateArticle(widget.article!.id, articleData, token);
        debugPrint('[EDIT] Update result: $success');

        // ✅ Upload gambar baru jika dipilih
        if (success && _selectedImage != null) {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://10.0.2.2:8080/api/media/create'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.fields['article_id'] = widget.article!.id.toString();
          request.fields['media_type'] = 'image';
          request.files.add(
              await http.MultipartFile.fromPath('media', _selectedImage!.path));
          final response = await request.send();
          debugPrint('[MEDIA] Upload response: ${response.statusCode}');
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artikel berhasil diupdate!')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal update artikel!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat/mengupdate artikel: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.article != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Artikel' : 'Buat Artikel',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Artikel',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi Artikel',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Isi artikel wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (_oldImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _oldImageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey),
                            ),
                          )),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitArticle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? 'Update Artikel' : 'Kirim Artikel',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
