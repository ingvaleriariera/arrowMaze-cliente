import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:arrow_maze_cliente/adapters/repositories/game_progress_repository_impl.dart';
import 'package:arrow_maze_cliente/ui/app/my_app.dart';
import 'package:arrow_maze_cliente/ui/providers/providers.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    // No platform channel handler exists in widget tests, so stub the
    // secure-storage calls the splash screen's auth check makes.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_secureStorageChannel, null);
    });

    // sqflite_common_ffi does real native I/O, which testWidgets' fake-async
    // zone never drains — it must run inside tester.runAsync() or it hangs.
    final database = await tester.runAsync(() => databaseFactory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(GameProgressRepositoryImpl.createTableSql);
            },
          ),
        ));
    addTearDown(() => database!.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database!)],
        child: const MyApp(),
      ),
    );

    expect(find.text('ARROW\nMAZE'), findsOneWidget);

    // Drain the splash screen's 1.5s navigation timer so no Timer is left
    // pending once the widget tree is disposed at the end of the test.
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
