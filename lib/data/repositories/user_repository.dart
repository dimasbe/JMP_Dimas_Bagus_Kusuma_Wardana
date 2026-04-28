import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../../core/utils/hash_helper.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Login: cari user berdasarkan username & password
  Future<UserModel?> login(String username, String password) async {
    final db = await _db.database;
    final passwordHash = HashHelper.hashPassword(password);
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, passwordHash],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  /// Ambil user berdasarkan ID
  Future<UserModel?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  /// Ganti password
  Future<void> changePassword(int userId, String newPassword) async {
    final db = await _db.database;
    await db.update(
      'users',
      {'password': HashHelper.hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Tambah user baru
  Future<int> insert(UserModel user) async {
    final db = await _db.database;
    return db.insert('users', user.toMap());
  }

  /// Cek apakah username sudah dipakai
  Future<bool> isUsernameExists(String username) async {
    final db = await _db.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }
}
