import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'adapters/repositories/game_progress_repository_impl.dart';
import 'ui/app/my_app.dart';
import 'ui/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Inicializar SQLite ────────────────────────────────────
  // sqflite_common_ffi_web no soporta paths de filesystem: solo un nombre.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  final dbName = kIsWeb ? 'arrow_maze.db' : '${await getDatabasesPath()}/arrow_maze.db';
  final database = await openDatabase(
    dbName,
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
