import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/lift_entry.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      path.join(root, 'liftlog_pro.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          password_salt TEXT NOT NULL,
          goal INTEGER NOT NULL DEFAULT 4,
          created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          muscle_group TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL NOT NULL,
          day TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )''');
        await db.execute('''CREATE TABLE progress_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          file_path TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )''');
      },
    );
    return _database!;
  }

  Future<List<Map<String, Object?>>> _webRows(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('liftlog_web_$key');
    if (encoded == null) return [];
    final rows = jsonDecode(encoded) as List<dynamic>;
    return rows.map((row) => Map<String, Object?>.from(row as Map)).toList();
  }

  Future<void> _saveWebRows(String key, List<Map<String, Object?>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('liftlog_web_$key', jsonEncode(rows));
  }

  Future<int> _nextWebId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt('liftlog_web_${key}_next_id') ?? 0) + 1;
    await prefs.setInt('liftlog_web_${key}_next_id', next);
    return next;
  }

  String _passwordDigest(String salt, String password) => sha256.convert(utf8.encode('$salt:$password')).toString();

  Map<String, Object?> _withoutPassword(Map<String, Object?> row) {
    final user = Map<String, Object?>.from(row)
      ..remove('password_hash')
      ..remove('password_salt');
    return user;
  }

  Future<Map<String, Object?>?> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (kIsWeb) {
      final users = await _webRows('users');
      for (final user in users) {
        if (user['email'] == normalizedEmail &&
            _passwordDigest(user['password_salt'] as String, password) == user['password_hash']) {
          return _withoutPassword(user);
        }
      }
      return null;
    }
    final rows = await (await database).query('users', where: 'email = ?', whereArgs: [normalizedEmail], limit: 1);
    if (rows.isEmpty) return null;
    final row = Map<String, Object?>.from(rows.first);
    if (_passwordDigest(row['password_salt'] as String, password) != row['password_hash']) return null;
    return _withoutPassword(row);
  }

  Future<Map<String, Object?>?> userById(int id) async {
    if (kIsWeb) {
      final users = await _webRows('users');
      for (final user in users) {
        if (user['id'] == id) return _withoutPassword(user);
      }
      return null;
    }
    final rows = await (await database).query('users', columns: ['id', 'name', 'email', 'goal'], where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final salt = base64UrlEncode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final createdAt = DateTime.now().toIso8601String();
    if (kIsWeb) {
      final users = await _webRows('users');
      if (users.any((user) => user['email'] == normalizedEmail)) {
        throw StateError('EMAIL_ALREADY_EXISTS');
      }
      final id = await _nextWebId('users');
      users.add({
        'id': id,
        'name': name.trim(),
        'email': normalizedEmail,
        'password_hash': _passwordDigest(salt, password),
        'password_salt': salt,
        'goal': 4,
        'created_at': createdAt,
      });
      await _saveWebRows('users', users);
      return id;
    }
    final db = await database;
    final existing = await db.query('users', columns: ['id'], where: 'email = ?', whereArgs: [normalizedEmail], limit: 1);
    if (existing.isNotEmpty) throw StateError('EMAIL_ALREADY_EXISTS');
    return db.insert('users', {
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': _passwordDigest(salt, password),
      'password_salt': salt,
      'goal': 4,
      'created_at': createdAt,
    });
  }

  Future<void> updateUser(int id, {String? name, int? goal}) async {
    final values = <String, Object?>{};
    if (name != null) values['name'] = name.trim();
    if (goal != null) values['goal'] = goal;
    if (values.isEmpty) return;
    if (kIsWeb) {
      final users = await _webRows('users');
      final index = users.indexWhere((user) => user['id'] == id);
      if (index < 0) return;
      users[index].addAll(values);
      await _saveWebRows('users', users);
      return;
    }
    await (await database).update('users', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LiftEntry>> exercises(int userId) async {
    if (kIsWeb) {
      final rows = await _webRows('exercises');
      return rows.where((row) => row['user_id'] == userId).map(LiftEntry.fromMap).toList();
    }
    final rows = await (await database).query('exercises', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return rows.map(LiftEntry.fromMap).toList();
  }

  Future<int> saveExercise(int userId, LiftEntry entry) async {
    if (kIsWeb) {
      final rows = await _webRows('exercises');
      final id = entry.id ?? await _nextWebId('exercises');
      final values = entry.toMap()
        ..['id'] = id
        ..['user_id'] = userId;
      final index = rows.indexWhere((row) => row['id'] == id && row['user_id'] == userId);
      if (index < 0) {
        rows.add(values);
      } else {
        rows[index] = values;
      }
      await _saveWebRows('exercises', rows);
      return id;
    }
    final values = entry.toMap()..remove('id');
    values['user_id'] = userId;
    final db = await database;
    if (entry.id == null) return db.insert('exercises', values);
    await db.update('exercises', values, where: 'id = ? AND user_id = ?', whereArgs: [entry.id, userId]);
    return entry.id!;
  }

  Future<void> deleteExercise(int userId, int id) async {
    if (kIsWeb) {
      final rows = await _webRows('exercises');
      rows.removeWhere((row) => row['id'] == id && row['user_id'] == userId);
      await _saveWebRows('exercises', rows);
      return;
    }
    await (await database).delete('exercises', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  Future<void> savePhoto(int userId, String dataUri) async {
    if (kIsWeb) {
      final rows = await _webRows('photos');
      rows.add({'id': await _nextWebId('photos'), 'user_id': userId, 'file_path': dataUri, 'created_at': DateTime.now().toIso8601String()});
      await _saveWebRows('photos', rows);
      return;
    }
    await (await database).insert('progress_photos', {'user_id': userId, 'file_path': dataUri, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, Object?>>> photos(int userId) async {
    if (kIsWeb) {
      final rows = (await _webRows('photos')).where((row) => row['user_id'] == userId).toList();
      rows.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      return rows;
    }
    return (await database).query('progress_photos', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
  }

  Future<void> deletePhoto(int userId, int id) async {
    if (kIsWeb) {
      final rows = await _webRows('photos');
      rows.removeWhere((row) => row['id'] == id && row['user_id'] == userId);
      await _saveWebRows('photos', rows);
      return;
    }
    await (await database).delete('progress_photos', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }
}
