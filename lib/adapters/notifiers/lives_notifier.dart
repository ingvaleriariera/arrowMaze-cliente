import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/lives_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/buy_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/get_lives_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/lose_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';

/// Single owner of every life mutation (defeats, abandons, purchases,
/// regeneration), so screens only ever read this state and call intents.
class LivesNotifier extends StateNotifier<LivesState> {
  final GetLivesUseCase getLivesUseCase;
  final LoseLifeUseCase loseLifeUseCase;
  final BuyLifeUseCase buyLifeUseCase;

  String? _userId;
  Timer? _ticker;

  LivesNotifier({
    required this.getLivesUseCase,
    required this.loseLifeUseCase,
    required this.buyLifeUseCase,
  }) : super(const LivesState());

  Future<void> load(String userId) async {
    _userId = userId;
    state = state.copyWith(isLoading: true);
    final lives = await getLivesUseCase.execute(userId);
    _emit(lives);
  }

  Future<void> loseLife() async {
    final userId = _userId;
    if (userId == null) return;
    final lives = await loseLifeUseCase.execute(userId);
    debugPrint('💔 LivesNotifier: Life lost — now ${lives.lives}/${PlayerLives.maxLives}');
    _emit(lives);
  }

  /// Returns true when the purchase went through (enough coins and the
  /// pool wasn't full).
  Future<bool> buyLife() async {
    final userId = _userId;
    if (userId == null) return false;
    final lives = await buyLifeUseCase.execute(userId);
    if (lives == null) return false;
    debugPrint('❤️  LivesNotifier: Life bought — now ${lives.lives}/${PlayerLives.maxLives}');
    _emit(lives);
    return true;
  }

  void _emit(PlayerLives lives) {
    state = LivesState(
      lives: lives,
      isLoading: false,
      timeUntilNextLife: lives.timeUntilNextLife(DateTime.now()),
    );
    _syncTicker(lives);
  }

  /// One-second ticker, alive only while a life is regenerating: refreshes
  /// the countdown shown on the Home screen and rolls the pool forward the
  /// moment a regeneration comes due.
  void _syncTicker(PlayerLives lives) {
    _ticker?.cancel();
    _ticker = null;
    if (lives.isFull) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.lives;
      if (current == null) return;

      final now = DateTime.now();
      final regenerated = current.regenerated(now);
      if (regenerated.lives != current.lives) {
        // A life just came due — persist it and re-anchor the ticker.
        final userId = _userId;
        if (userId != null) {
          unawaited(getLivesUseCase.execute(userId).then(_emit));
        } else {
          _emit(regenerated);
        }
        return;
      }

      state = state.copyWith(
        timeUntilNextLife: current.timeUntilNextLife(now),
        clearCountdown: current.isFull,
      );
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
