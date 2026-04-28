import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/hash_helper.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      // SQLite tidak mengaktifkan foreign key secara default.
      // Harus diaktifkan di setiap koneksi agar ON DELETE CASCADE berfungsi.
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Tabel users ──────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nama        TEXT NOT NULL,
        username    TEXT UNIQUE NOT NULL,
        password    TEXT NOT NULL,
        created_at  TEXT NOT NULL
      )
    ''');

    // ── Tabel stores ─────────────────────────────────
    await db.execute('''
      CREATE TABLE stores (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pemilik    TEXT NOT NULL,
        nama_toko       TEXT NOT NULL,
        alamat          TEXT NOT NULL,
        latitude        REAL NOT NULL,
        longitude       REAL NOT NULL,
        jumlah_terima   INTEGER NOT NULL,
        tanggal_terima  TEXT NOT NULL,
        foto_toko       TEXT,
        created_at      TEXT NOT NULL
      )
    ''');

    // ── Tabel survey_records ──────────────────────────
    await db.execute('''
      CREATE TABLE survey_records (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id        INTEGER NOT NULL,
        user_id         INTEGER NOT NULL,
        jumlah_saat_ini INTEGER NOT NULL,
        tanggal_survei  TEXT NOT NULL,
        foto_bukti      TEXT NOT NULL,
        catatan         TEXT,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id)  REFERENCES users(id)
      )
    ''');

    // ── Seed akun admin default ───────────────────────
    await db.insert('users', UserModel(
      nama: AppConstants.defaultNama,
      username: AppConstants.defaultUsername,
      password: HashHelper.hashPassword(AppConstants.defaultPassword),
      createdAt: DateTime.now().toIso8601String(),
    ).toMap());
  }
}
