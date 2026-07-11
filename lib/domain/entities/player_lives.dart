/// The player's life pool: capped at [maxLives], one life lost per defeat
/// (or per abandoned run), regenerating one life every [regenInterval]
/// while below the cap.
///
/// Immutable — every mutation returns a new instance — and every
/// time-dependent method takes `now` as a parameter instead of reading the
/// clock itself, so the regeneration rules are fully unit-testable.
class PlayerLives {
  static const int maxLives = 5;
  static const Duration regenInterval = Duration(minutes: 20);

  final int lives;

  /// When the next life will be granted; null while the pool is full.
  final DateTime? nextRegenAt;

  const PlayerLives({required this.lives, this.nextRegenAt})
      : assert(lives >= 0 && lives <= maxLives);

  factory PlayerLives.full() => const PlayerLives(lives: maxLives);

  bool get canPlay => lives > 0;
  bool get isFull => lives >= maxLives;

  /// Applies every regeneration that has come due since the state was
  /// last saved. Catch-up is cumulative: being away for an hour with the
  /// 20-minute interval grants three lives (capped), not one.
  PlayerLives regenerated(DateTime now) {
    var newLives = lives;
    var anchor = nextRegenAt;

    while (anchor != null && newLives < maxLives && !now.isBefore(anchor)) {
      newLives++;
      anchor = newLives < maxLives ? anchor.add(regenInterval) : null;
    }

    return PlayerLives(lives: newLives, nextRegenAt: anchor);
  }

  /// Losing a life from a full pool starts the regeneration clock; losing
  /// one while already below the cap keeps the existing countdown (the
  /// life already "in production" isn't delayed by further losses).
  PlayerLives afterLosingLife(DateTime now) {
    if (lives == 0) return this;
    return PlayerLives(
      lives: lives - 1,
      nextRegenAt: nextRegenAt ?? now.add(regenInterval),
    );
  }

  /// A purchased life is granted instantly; if it tops the pool back up,
  /// the regeneration clock stops.
  PlayerLives afterGainingLife() {
    if (isFull) return this;
    final newLives = lives + 1;
    return PlayerLives(
      lives: newLives,
      nextRegenAt: newLives >= maxLives ? null : nextRegenAt,
    );
  }

  Duration? timeUntilNextLife(DateTime now) {
    final anchor = nextRegenAt;
    if (anchor == null) return null;
    final remaining = anchor.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  String toString() => 'PlayerLives($lives/$maxLives, next: $nextRegenAt)';
}
