import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GameProgressDatabase {
  static const _databaseName = 'arrow_maze.db';
  static const _tableName = 'game_progress';
  static const _version = 1;

  static final GameProgressDatabase _instance = GameProgressDatabase._internal();

  factory GameProgressDatabase() {
    return _instance;
  }

  GameProgressDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    debugPrint('🗄️  GameProgressDatabase: Initializing database');
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: (Database db, int version) async {
        debugPrint('🗄️  GameProgressDatabase: Creating tables');
        await db.execute('''
          CREATE TABLE $_tableName (
            userId TEXT PRIMARY KEY,
            completedLevels TEXT NOT NULL,
            bestScores TEXT NOT NULL,
            coins INTEGER NOT NULL,
            avatarEmoji TEXT NOT NULL,
            lastUpdated INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> getProgress(String userId) async {
    try {
      debugPrint('📖 GameProgressDatabase.getProgress: Reading $userId from sqflite');
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );

      if (maps.isEmpty) {
        debugPrint('ℹ️  GameProgressDatabase: No progress found for $userId');
        return null;
      }

      debugPrint('✅ GameProgressDatabase: Found progress for $userId');
      return maps.first;
    } catch (e) {
      debugPrint('❌ GameProgressDatabase.getProgress: Error - $e');
      rethrow;
    }
  }

  Future<void> saveProgress(
    String userId,
    List<String> completedLevels,
    Map<String, int> bestScores,
    int coins,
    String avatarEmoji,
  ) async {
    try {
      debugPrint('💾 GameProgressDatabase.saveProgress: Saving $userId to sqflite');
      final db = await database;

      await db.insert(
        _tableName,
        {
          'userId': userId,
          'completedLevels': jsonEncode(completedLevels),
          'bestScores': jsonEncode(bestScores),
          'coins': coins,
          'avatarEmoji': avatarEmoji,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('✅ GameProgressDatabase: Saved $userId to sqflite');
    } catch (e) {
      debugPrint('❌ GameProgressDatabase.saveProgress: Error - $e');
      rethrow;
    }
  }

  Future<void> deleteProgress(String userId) async {
    try {
      debugPrint('🗑️  GameProgressDatabase.deleteProgress: Deleting $userId');
      final db = await database;
      await db.delete(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );
      debugPrint('✅ GameProgressDatabase: Deleted $userId');
    } catch (e) {
      debugPrint('❌ GameProgressDatabase.deleteProgress: Error - $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      debugPrint('🗄️  GameProgressDatabase: Database closed');
    }
  }
}
