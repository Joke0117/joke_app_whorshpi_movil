import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';

// PBKDF2 manual (crypto 3.0.6 no lo incluye)
Uint8List _pbkdf2HmacSha256(Uint8List password, Uint8List salt, int iterations, int keyLength) {
  final hLen = 32;
  final l = (keyLength + hLen - 1) ~/ hLen;
  final dk = <int>[];
  for (int block = 1; block <= l; block++) {
    final blockBytes = ByteData(4)..setUint32(0, block, Endian.big);
    final blockSalt = Uint8List.fromList([...salt, ...blockBytes.buffer.asUint8List()]);
    var u = Hmac(sha256, password).convert(blockSalt).bytes;
    var t = Uint8List.fromList(u);
    for (int j = 1; j < iterations; j++) {
      u = Hmac(sha256, password).convert(u).bytes;
      for (int k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    dk.addAll(t);
  }
  return Uint8List.fromList(dk.sublist(0, keyLength));
}

class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String? photoPath;
  final String? email;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    this.photoPath,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'photoPath': photoPath,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      passwordHash: map['passwordHash'],
      photoPath: map['photoPath'],
      email: map['email'],
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? photoPath,
    String? email,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      photoPath: photoPath ?? this.photoPath,
      email: email ?? this.email,
    );
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('worship_users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        photoPath TEXT,
        email TEXT
      )
    ''');
  }

  // ── PBKDF2 con SHA-256 (seguro) ────────────────────────────────────────
  static const _pbkdf2Prefix = 'pbkdf2|';
  static const _iterations = 60000;
  static const _keyLength = 32;

  String _hashPassword(String password) {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final key = _pbkdf2HmacSha256(
      Uint8List.fromList(utf8.encode(password)),
      Uint8List.fromList(salt),
      _iterations,
      _keyLength,
    );
    return '$_pbkdf2Prefix${base64.encode(salt)}|${base64.encode(key)}';
  }

  bool _verifyPassword(String password, String storedHash) {
    if (!storedHash.startsWith(_pbkdf2Prefix)) {
      // Formato legacy: SHA-256 sin salt — migrar en el login
      return sha256.convert(utf8.encode(password)).toString() == storedHash;
    }
    final parts = storedHash.split('|');
    if (parts.length != 3) return false;
    final salt = base64.decode(parts[1]);
    final storedKey = parts[2];
    final computedKey = _pbkdf2HmacSha256(
      Uint8List.fromList(utf8.encode(password)),
      Uint8List.fromList(salt),
      _iterations,
      _keyLength,
    );
    return base64.encode(computedKey) == storedKey;
  }

  Future<UserModel?> registerUser({
    required String username,
    required String password,
    String? email,
    String? photoPath,
  }) async {
    final db = await database;
    final hash = _hashPassword(password);

    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (existing.isNotEmpty) return null;

    final user = UserModel(
      username: username,
      passwordHash: hash,
      email: email,
      photoPath: photoPath,
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<UserModel?> loginUser({
    required String username,
    required String password,
  }) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;

    final user = UserModel.fromMap(result.first);
    if (!_verifyPassword(password, user.passwordHash)) return null;

    // Migración automática: si era SHA-256 legacy, lo actualizamos a PBKDF2
    if (!user.passwordHash.startsWith(_pbkdf2Prefix)) {
      final newHash = _hashPassword(password);
      await db.update(
        'users',
        {'passwordHash': newHash},
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return user.copyWith(passwordHash: newHash);
    }

    return user;
  }

  Future<bool> updateUserPhoto({
    required int userId,
    required String photoPath,
  }) async {
    final db = await database;
    final count = await db.update(
      'users',
      {'photoPath': photoPath},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  Future<bool> updateUserProfile({
    required int userId,
    String? email,
    String? photoPath,
  }) async {
    final db = await database;
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (photoPath != null) map['photoPath'] = photoPath;
    if (map.isEmpty) return false;

    final count = await db.update(
      'users',
      map,
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ── Recuperar / Actualizar Contraseña ──────────────────────────────────
  Future<bool> updatePassword(String username, String newPassword) async {
    final db = await database;

    final users = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (users.isEmpty) return false;

    final hash = _hashPassword(newPassword);
    final count = await db.update(
      'users',
      {'passwordHash': hash},
      where: 'username = ?',
      whereArgs: [username],
    );
    return count > 0;
  }
}

