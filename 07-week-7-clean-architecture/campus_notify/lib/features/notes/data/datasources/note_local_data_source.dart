import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class NoteLocalDataSource {
  Future<Database> getDatabase();
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  Database? _db;

  @override
  Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            dirty INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }
}

Future<Database> openNotesDb() async {
  final dataSource = NoteLocalDataSourceImpl();
  return dataSource.getDatabase();
}
