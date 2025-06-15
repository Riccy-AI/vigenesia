import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;

  String? _initialUsername;
  String? _initialEmail;
  int? _lastUserId;

  // Helper untuk membentuk URL foto profil
  String? getProfilePictureUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    const baseUrl = 'http://10.0.2.2:8080/uploads/profile/';
    return '$baseUrl$filename';
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();

    _initialUsername = user?.username;
    _initialEmail = user?.email;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context).user;
    if (user != null && user.id != _lastUserId) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _profileImage = null; // reset ke null agar ambil dari network lagi
      _lastUserId = user.id;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
        });
        debugPrint('Gambar dipilih: ${picked.path}');
      }
    } catch (e) {
      debugPrint('Gagal memilih gambar: $e');
    }
  }

  bool _isFormChanged() {
    return _usernameController.text.trim() != _initialUsername ||
        _emailController.text.trim() != _initialEmail ||
        _passwordController.text.isNotEmpty ||
        _profileImage != null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isFormChanged()) {
      setState(() => _errorMessage = 'Tidak ada perubahan yang dilakukan.');
      debugPrint('Tidak ada perubahan yang dilakukan.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      debugPrint('User tidak ditemukan');
      return;
    }

    try {
      final uri = Uri.parse('http://10.0.2.2:8080/api/users/update/${user.id}');
      final request = http.MultipartRequest('POST', uri);
      request.fields['_method'] = 'PUT'; // simulasikan PUT

// Ambil token dari AuthProvider
      final token = authProvider.token;
      debugPrint('Token JWT: $token');

// Tambahkan header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      if (_usernameController.text.trim().isNotEmpty &&
          _usernameController.text.trim() != _initialUsername) {
        request.fields['username'] = _usernameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty &&
          !_emailController.text.contains('@')) {
        setState(() => _errorMessage = 'Format email tidak valid.');
        return;
      }

      if (_passwordController.text.isNotEmpty) {
        request.fields['password'] = _passwordController.text;
      }
      if (_profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          _profileImage!.path,
        ));
      }

      debugPrint('Data yang dikirim: ${request.fields}');
      if (_profileImage != null) {
        debugPrint('File gambar: ${_profileImage!.path}');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await authProvider.refreshUserProfile(); // <--- WAJIB
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context,
              true); // <--- return true agar UserProfileScreen tahu harus rebuild
        }
      } else {
        setState(() => _errorMessage = 'Gagal memperbarui profil.');
      }
    } catch (e) {
      debugPrint('Terjadi error saat submit: $e');
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (user?.profilePicture != null &&
                                user!.profilePicture!.isNotEmpty
                            ? NetworkImage(user.profilePicture!
                                    .startsWith('http')
                                ? user.profilePicture!
                                : 'http://10.0.2.2:8080/uploads/profile/${user.profilePicture!}')
                            : const AssetImage('assets/images/ubsi.png')
                                as ImageProvider),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Simpan Perubahan'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.blue[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _submit,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
