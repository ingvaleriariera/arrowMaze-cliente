import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);

  group('PlayerLives', () {
    test('starts full and playable, with no regen clock running', () {
      final lives = PlayerLives.full();
      expect(lives.lives, PlayerLives.maxLives);
      expect(lives.canPlay, isTrue);
      expect(lives.nextRegenAt, isNull);
      expect(lives.timeUntilNextLife(t0), isNull);
    });

    test('losing a life from full starts the regeneration clock', () {
      final lives = PlayerLives.full().afterLosingLife(t0);
      expect(lives.lives, PlayerLives.maxLives - 1);
      expect(lives.nextRegenAt, t0.add(PlayerLives.regenInterval));
    });

    test('further losses do not delay the life already regenerating', () {
      final afterOne = PlayerLives.full().afterLosingLife(t0);
      final afterTwo =
          afterOne.afterLosingLife(t0.add(const Duration(minutes: 5)));
      expect(afterTwo.lives, PlayerLives.maxLives - 2);
      expect(afterTwo.nextRegenAt, afterOne.nextRegenAt);
    });

    test('cannot go below zero lives', () {
      var lives = PlayerLives.full();
      for (int i = 0; i < PlayerLives.maxLives + 3; i++) {
        lives = lives.afterLosingLife(t0);
      }
      expect(lives.lives, 0);
      expect(lives.canPlay, isFalse);
    });

    test('regenerates one life when the interval elapses', () {
      final depleted = PlayerLives.full().afterLosingLife(t0);
      final regenerated =
          depleted.regenerated(t0.add(PlayerLives.regenInterval));
      expect(regenerated.lives, PlayerLives.maxLives);
      expect(regenerated.nextRegenAt, isNull);
    });

    test('catch-up regeneration grants multiple lives after a long absence', () {
      var lives = PlayerLives.full();
      for (int i = 0; i < 3; i++) {
        lives = lives.afterLosingLife(t0);
      }
      expect(lives.lives, 2);

      final later = t0.add(PlayerLives.regenInterval * 2);
      final regenerated = lives.regenerated(later);
      expect(regenerated.lives, 4);
      expect(regenerated.nextRegenAt, isNotNull);
    });

    test('regeneration never exceeds the cap', () {
      final depleted = PlayerLives.full().afterLosingLife(t0);
      final wayLater = depleted.regenerated(t0.add(const Duration(days: 1)));
      expect(wayLater.lives, PlayerLives.maxLives);
      expect(wayLater.nextRegenAt, isNull);
    });

    test('buying a life grants it instantly and stops the clock at full', () {
      final depleted = PlayerLives.full().afterLosingLife(t0);
      final bought = depleted.afterGainingLife();
      expect(bought.lives, PlayerLives.maxLives);
      expect(bought.nextRegenAt, isNull);
    });

    test('buying while full is a no-op', () {
      final full = PlayerLives.full();
      expect(full.afterGainingLife(), full);
    });

    test('countdown reports the remaining wait, floored at zero', () {
      final depleted = PlayerLives.full().afterLosingLife(t0);
      final halfway =
          depleted.timeUntilNextLife(t0.add(const Duration(minutes: 10)));
      expect(halfway, const Duration(minutes: 10));

      final overdue =
          depleted.timeUntilNextLife(t0.add(const Duration(minutes: 25)));
      expect(overdue, Duration.zero);
    });
  });
}
