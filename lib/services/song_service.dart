import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';

class SongService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pad_worship_songs.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL DEFAULT '',
            key TEXT NOT NULL DEFAULT 'C',
            isMinor INTEGER NOT NULL DEFAULT 0,
            rawLyrics TEXT NOT NULL DEFAULT '',
            "order" INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  static Future<List<Song>> getAll() async {
    final db = await database;
    final maps = await db.query('songs', orderBy: '"order" ASC, id ASC');
    return maps.map(Song.fromMap).toList();
  }

  static Future<Song> insert(Song song) async {
    final db = await database;
    final id = await db.insert('songs', song.toMap()..remove('id'));
    return song.copyWith(id: id);
  }

  static Future<void> update(Song song) async {
    final db = await database;
    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> reorder(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < songs.length; i++) {
      batch.update(
        'songs',
        {'"order"': i},
        where: 'id = ?',
        whereArgs: [songs[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
