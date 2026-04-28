import '../database/database_helper.dart';
import '../models/store_model.dart';

class StoreRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Ambil semua toko, urutkan dari terbaru
  Future<List<StoreModel>> getAll() async {
    final db = await _db.database;
    final result = await db.query('stores', orderBy: 'created_at DESC');
    return result.map(StoreModel.fromMap).toList();
  }

  /// Cari toko berdasarkan nama toko atau nama pemilik
  Future<List<StoreModel>> search(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'stores',
      where: 'nama_toko LIKE ? OR nama_pemilik LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nama_toko ASC',
    );
    return result.map(StoreModel.fromMap).toList();
  }

  /// Ambil satu toko berdasarkan ID
  Future<StoreModel?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('stores', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return StoreModel.fromMap(result.first);
  }

  /// Tambah toko baru
  Future<int> insert(StoreModel store) async {
    final db = await _db.database;
    return db.insert('stores', store.toMap());
  }

  /// Update data toko
  Future<void> update(StoreModel store) async {
    final db = await _db.database;
    await db.update(
      'stores',
      store.toMap(),
      where: 'id = ?',
      whereArgs: [store.id],
    );
  }

  /// Hapus toko beserta semua survey_records terkait
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Hapus survey_records terlebih dahulu (safeguard jika CASCADE belum aktif)
      await txn.delete('survey_records', where: 'store_id = ?', whereArgs: [id]);
      // Baru hapus tokonya
      await txn.delete('stores', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Hitung total toko
  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM stores');
    return result.first['count'] as int;
  }
}
