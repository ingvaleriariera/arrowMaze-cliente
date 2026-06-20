import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';

/// Root de la aplicación.
/// MaterialApp.router + Riverpod + ThemeData oscuro + localizations.
// TODO: AppLocalizations — strings hardcoded in ES for MVP
// Full i18n implementation deferred (technical debt)
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Arrow Maze',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // ─── Localización ────────────────────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      // ─── Tema oscuro coherente con #0d0d18 ───────────────────
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    const bgColor = Color(0xFF0D0D18);
    const panelColor = Color(0xFF0F0F1E);
    const primaryNeon = Color(0xFF00F5A0);
    const borderColor = Color(0xFF1A1A2E);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        surface: bgColor,
        primary: primaryNeon,
        secondary: Color(0xFF00DDFF),
        error: Color(0xFFFF3366),
      ),
      fontFamily: 'monospace',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primaryNeon,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
        headlineMedium: TextStyle(
          color: primaryNeon,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFEEEEEE),
          fontFamily: 'monospace',
        ),
        labelSmall: TextStyle(
          color: Color(0xFF555555),
          letterSpacing: 1,
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: panelColor,
        foregroundColor: primaryNeon,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryNeon,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          fontSize: 16,
          fontFamily: 'monospace',
        ),
      ),
      dividerColor: borderColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primaryNeon,
          side: const BorderSide(color: primaryNeon),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryNeon),
        ),
        labelStyle: const TextStyle(color: Color(0xFF555555), fontFamily: 'monospace'),
        hintStyle: const TextStyle(color: Color(0xFF333355), fontFamily: 'monospace'),
      ),
    );
  }
}
