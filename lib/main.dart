import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'adapters/repositories/game_progress_repository_impl.dart';
import 'ui/app/my_app.dart';
import 'ui/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Inicializar SQLite ────────────────────────────────────
  final dbPath = await getDatabasesPath();
  final database = await openDatabase(
    '$dbPath/arrow_maze.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute(GameProgressRepositoryImpl.createTableSql);
    },
  );

  // ─── Lanzar app con ProviderScope ─────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        // Inyectamos la base de datos inicializada
        databaseProvider.overrideWithValue(database),
      ],
      child: const MyApp(),
    ),
  );
}
