import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/splash_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/login_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/register_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/home_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/profile_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/level_select_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/game_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/victory_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/defeat_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/leaderboard_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/settings_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/boards_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/board_editor_screen.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/screens/hex_board_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/levels',
        builder: (context, state) => const LevelSelectScreen(),
      ),
      GoRoute(
        path: '/boards',
        builder: (context, state) => const BoardsScreen(),
      ),
      GoRoute(
        path: '/boards/editor',
        builder: (context, state) => const BoardEditorScreen(),
      ),
      GoRoute(
        path: '/hex-board',
        builder: (context, state) => const HexBoardScreen(),
      ),
      GoRoute(
        path: '/game/:levelId',
        builder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          final extra = state.extra;
          final difficulty = extra is Map ? extra['difficulty'] as String? : null;
          final levelNumber = extra is Map ? extra['levelNumber'] as int? : null;
          final title = extra is Map ? extra['title'] as String? : null;
          return GameScreen(
            levelId: levelId,
            difficulty: difficulty,
            levelNumber: levelNumber,
            title: title,
          );
        },
      ),
      GoRoute(
        path: '/victory',
        builder: (context, state) => const VictoryScreen(),
      ),
      GoRoute(
        path: '/defeat',
        builder: (context, state) => const DefeatScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      // TODO: Add authentication checks
      // If user is not authenticated and trying to access protected routes
      return null;
    },
  );
}
