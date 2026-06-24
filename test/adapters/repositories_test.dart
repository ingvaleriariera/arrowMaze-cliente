import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/level_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/auth_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/game_progress_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/leaderboard_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/level_repository_impl.dart';
import 'test/adapters/mocks/mock_dio.dart';

void main() {
  group('Adapter Layer - Repositories', () {
    late MockDio mockDio;
    late ApiClient apiClient;

    setUp(() {
      mockDio = MockDio();
      apiClient = ApiClient(
        baseUrl: 'https://api.test.com',
        dio: mockDio,
      );
    });

    test('Scenario 1: AuthRepositoryImpl.login saves token and calls setToken', () async {
      mockDio.setMockResponse('/auth/login', {
        'token': 'test_token_123',
        'userId': 'user_123',
      });

      final authRepo = AuthRepositoryImpl(apiClient: apiClient);
      final result = await authRepo.login('test@example.com', 'password123');

      expect(result.token, equals('test_token_123'));
      expect(result.userId, equals('user_123'));
      expect(apiClient._dio.options.headers['Authorization'], equals('Bearer test_token_123'));
    });

    test('Scenario 2: AuthRepositoryImpl.logout clears token', () async {
      apiClient.setToken('test_token_123');
      expect(apiClient._dio.options.headers.containsKey('Authorization'), isTrue);

      final authRepo = AuthRepositoryImpl(apiClient: apiClient);
      await authRepo.logout();

      expect(apiClient._dio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('Scenario 3: GameProgressRepositoryImpl.sync resolves with backend win', () async {
      final progressRepo = GameProgressRepositoryImpl(
        apiClient: apiClient,
        progressMapper: ProgressMapper(),
      );

      mockDio.setMockResponse('/progress/user_123', {
        'userId': 'user_123',
        'completedLevels': ['level_001'],
        'bestScores': {'level_001': 500},
        'coins': 100,
      });

      final synced = await progressRepo.sync('user_123');

      expect(synced.userId, equals('user_123'));
      expect(synced.coins, equals(100));
      expect(synced.isCompleted('level_001'), isTrue);
    });

    test('Scenario 4: LevelRepositoryImpl.getLevel returns Level', () async {
      mockDio.setMockResponse('/levels/level_001', {
        'id': 'level_001',
        'difficulty': 'EASY',
        'boardLayout': '[[1,1,1],[1,1,1],[1,1,1]]',
        'moveLimit': 10,
        'timeLimitSeconds': 0,
      });

      final levelRepo = LevelRepositoryImpl(
        apiClient: apiClient,
        levelMapper: LevelMapper(),
      );

      final level = await levelRepo.getLevel('level_001');

      expect(level.id, equals('level_001'));
      expect(level.difficulty, equals('EASY'));
      expect(level.moveLimit, equals(10));
    });

    test('Scenario 5: LeaderboardRepositoryImpl.getTopScores returns entries', () async {
      mockDio.setMockResponse('/leaderboard/level_001?limit=10', {
        'entries': [
          {'rank': 1, 'username': 'player1', 'score': 500},
          {'rank': 2, 'username': 'player2', 'score': 450},
        ],
      });

      final leaderboardRepo = LeaderboardRepositoryImpl(apiClient: apiClient);
      final entries = await leaderboardRepo.getTopScores('level_001', 10);

      expect(entries.length, equals(2));
      expect(entries[0].username, equals('player1'));
      expect(entries[0].score, equals(500));
    });
  });
}
