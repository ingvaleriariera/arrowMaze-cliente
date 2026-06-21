import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/defeat_screen.dart';
import '../screens/game_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/level_select_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/victory_screen.dart';

/// Provider del router go_router con guard de auth.
/// Declarado aquí y consumido en MyApp.
final routerProvider = Provider<GoRouter>((ref) {
  // OJO: NO usar ref.watch aquí. GoRouter debe ser una instancia única
  // para toda la vida de la app — si este Provider se recalcula (porque
  // observa authNotifierProvider reactivamente), se crea un GoRouter
  // nuevo en cada cambio de auth, lo que resetea la navegación a
  // initialLocation y puede producir un loop infinito (p. ej.
  // restoreSession() cambia el auth state → se recrea el router → vuelve
  // a '/' → splash vuelve a llamar restoreSession() → ...).
  // redirect() ya se reevalúa en cada navegación, así que basta con
  // leer el estado actual con ref.read en ese momento.
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = ref.read(authNotifierProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final isPublic = loc == '/' || loc == '/login' || loc == '/register';
      if (!isAuth && !isPublic) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/levels',
        builder: (context, _) => const LevelSelectScreen(),
      ),
      GoRoute(
        path: '/game/:levelId',
        builder: (_, state) =>
            GameScreen(levelId: state.pathParameters['levelId']!),
      ),
      GoRoute(
        path: '/victory',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VictoryScreen(
            score: extra['score'] as int? ?? 0,
            levelId: extra['levelId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/defeat',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DefeatScreen(
            score: extra['score'] as int? ?? 0,
            levelId: extra['levelId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/leaderboard/:levelId',
        builder: (_, state) =>
            LeaderboardScreen(levelId: state.pathParameters['levelId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, _) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      body: Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(
            color: Color(0xFFFF3366),
            fontFamily: 'monospace',
          ),
        ),
      ),
    ),
  );
});
