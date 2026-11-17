import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'greenpulse.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE waste_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wasteType TEXT NOT NULL,
            priority TEXT NOT NULL,
            description TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertReport({
    required String wasteType,
    required String priority,
    required String description,
  }) async {
    final db = await database;

    return db.insert('waste_reports', {
      'wasteType': wasteType,
      'priority': priority,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final db = await database;

    return db.query(
      'waste_reports',
      orderBy: 'id DESC',
    );
  }
}