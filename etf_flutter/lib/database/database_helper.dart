import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/password.dart';

class DatabaseHelper {
  static Database? _db;
  static Database get db => _db!;

  static Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'etf.db');

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      ),
    );
    await _ensureDefaults();
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('INCOME','EXPENSE'))
      )''');
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('INCOME','EXPENSE')),
        amount REAL NOT NULL,
        txn_date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
      )''');
    await db.execute('''
      CREATE TABLE budgets (
        budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        UNIQUE (user_id, category_id, month, year),
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
      )''');
  }

  static Future<void> _ensureDefaults() async {
    if (await _count('users') == 0) {
      await _db!.insert('users', {
        'email': 'admin@etf.com',
        'password_hash': hashPassword('admin123'),
        'full_name': 'ETF User',
      });
    }
    if (await _count('categories') == 0) {
      const seeds = [
        ['Salary', 'INCOME'], ['Business', 'INCOME'],
        ['Food', 'EXPENSE'], ['Transport', 'EXPENSE'],
        ['Utilities', 'EXPENSE'], ['Rent', 'EXPENSE'],
        ['Health', 'EXPENSE'], ['Entertainment', 'EXPENSE'],
      ];
      for (final s in seeds) {
        await _db!.insert('categories', {'name': s[0], 'type': s[1]});
      }
    }
  }

  static Future<int> _count(String table) async {
    final r = await _db!.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return (r.first['c'] as num).toInt();
  }
}