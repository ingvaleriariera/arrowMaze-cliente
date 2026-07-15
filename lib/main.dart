import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite has no Flutter Web backend, so on web the progress repository
  // falls back to a shared_preferences-backed store (see
  // gameProgressDatabaseProvider in providers.dart). That store needs a
  // resolved SharedPreferences instance, which can only be obtained
  // asynchronously — hence overriding it here, before runApp(), rather
  // than inside the provider itself. Mobile never touches this path.
  final overrides = <Override>[];
  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    overrides.add(sharedPreferencesProvider.overrideWithValue(prefs));
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const MyApp(),
    ),
  );
}
