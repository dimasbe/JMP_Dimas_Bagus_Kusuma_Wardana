import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  /// Hash sebuah string menggunakan SHA-256
  static String hashPassword(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi password dengan hash yang tersimpan
  static bool verifyPassword(String input, String storedHash) {
    return hashPassword(input) == storedHash;
  }
}
