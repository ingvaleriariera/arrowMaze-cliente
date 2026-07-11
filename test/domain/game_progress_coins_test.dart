import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';

void main() {
  group('GameProgress coin awards', () {
    test('first completion awards the full score as coins', () {
      final progress = GameProgress(userId: 'u1');
      progress.recordCompletion('level-001', 400);
      expect(progress.coins, 400);
      expect(progress.isCompleted('level-001'), isTrue);
    });

    test('replaying a completed level awards the reduced replay fraction', () {
      final progress = GameProgress(userId: 'u1');
      progress.recordCompletion('level-001', 400);
      progress.recordCompletion('level-001', 200);
      expect(
        progress.coins,
        400 + (200 * GameProgress.replayCoinFactor).round(),
      );
    });

    test('best score only improves, regardless of coin awards', () {
      final progress = GameProgress(userId: 'u1');
      progress.recordCompletion('level-001', 400);
      progress.recordCompletion('level-001', 200);
      expect(progress.getBestScore('level-001'), 400);
    });
  });
}
