import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_router.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/interceptors/auth_interceptor.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/interceptors/logging_interceptor.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/interceptors/error_interceptor.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setup interceptors
    final apiClient = ref.watch(apiClientProvider);
    final authRepository = ref.watch(authRepositoryProvider);

    apiClient.addInterceptor(AuthInterceptor(authRepository: authRepository));
    apiClient.addInterceptor(LoggingInterceptor());
    apiClient.addInterceptor(ErrorInterceptor());

    return MaterialApp.router(
      title: 'Arrow Maze',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00F5A0),
        scaffoldBackgroundColor: const Color(0xFF0d0d18),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f0f1e),
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
