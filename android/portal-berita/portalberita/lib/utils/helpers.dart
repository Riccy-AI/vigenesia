import 'package:intl/intl.dart';

/// Format tanggal dari string ISO ke format lokal (dd MMM yyyy)
String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  } catch (e) {
    return dateStr;
  }
}

/// Potong teks jika terlalu panjang
String truncateText(String text, {int maxLength = 100}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Base URL untuk folder upload profile picture (ganti dengan URL server kamu)
const String _baseProfilePictureUrl = 'http://10.0.2.2:8080/uploads/profile/';

/// Buat URL lengkap dari nama file profile picture
String? getProfilePictureUrl(String? filename) {
  if (filename == null || filename.isEmpty) return null;

  // Kalau sudah URL lengkap (misal mulai http), return langsung
  if (filename.startsWith('http')) return filename;

  // Kalau cuma nama file, tambahkan base URL
  return _baseProfilePictureUrl + filename;
}


