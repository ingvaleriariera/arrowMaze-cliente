import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/bottom_tab_bar.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/arrow_showcase.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/no_lives_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  GameProgress? _progress;
  bool _isLoading = true;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return;

    try {
      final progress = await ref.read(getLocalProgressUseCaseProvider).execute(userId);
      await ref.read(livesNotifierProvider.notifier).load(userId);
      await ref.read(levelSelectNotifierProvider.notifier).loadSummaries(userId);
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      // An unguarded throw anywhere in this chain used to leave
      // _isLoading stuck true forever (spinner never resolves until the
      // next full remount) — any failure here must still release it.
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Re-reads local progress (coins) without re-triggering the lives or
  /// level-summaries loads — used after any action elsewhere (buying a
  /// life) that spends coins while this screen stays mounted, since
  /// [_progress] is otherwise a one-shot snapshot from [_load].
  Future<void> _refreshProgress() async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return;
    final progress = await ref.read(getLocalProgressUseCaseProvider).execute(userId);
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  /// The level the player left off at: first unlocked-but-not-completed
  /// one, or the last unlocked one if everything's already done. Only
  /// considers the numbered progression — adopted community boards (which
  /// are always "unlocked, not completed") must never become the Play
  /// button's target.
  ({LevelSummaryDTO level, int number})? _currentLevel(List<LevelSummaryDTO> allLevels) {
    final levels = allLevels.where((l) => l.displayName == null).toList();
    if (levels.isEmpty) return null;
    for (int i = 0; i < levels.length; i++) {
      if (levels[i].unlocked && !levels[i].completed) return (level: levels[i], number: i + 1);
    }
    for (int i = levels.length - 1; i >= 0; i--) {
      if (levels[i].unlocked) return (level: levels[i], number: i + 1);
    }
    return null;
  }

  void _playCurrentLevel(LevelSummaryDTO level, int number) {
    if (!ref.read(livesNotifierProvider).canPlay) {
      showNoLivesDialog(context).then((_) => _refreshProgress());
      return;
    }
    context.push('/game/${level.levelId}', extra: {
      'difficulty': level.difficulty,
      'levelNumber': number,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final levelSelectState = ref.watch(levelSelectNotifierProvider);
    final coins = _progress?.coins ?? 0;
    final avatarEmoji = _progress?.avatarEmoji ?? '🎮';
    final current = _currentLevel(levelSelectState.levels);

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d18),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, authState.username, avatarEmoji, coins),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (current != null) ArrowShowcase(onTap: () => _playCurrentLevel(current.level, current.number)),
                      const SizedBox(height: 28),
                      _isLoading || current == null
                          ? const CircularProgressIndicator(color: Color(0xFF00F5A0))
                          : _buildPlayButton(current.level, current.number, l10n),
                    ],
                  ),
                ),
              ),
            ),
            const BottomTabBar(active: AppTab.home),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String? username, String avatarEmoji, int coins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
          Consumer(builder: (context, ref, _) {
            final livesState = ref.watch(livesNotifierProvider);
            final countdown = livesState.timeUntilNextLife;
            // Tappable: opens the lives dialog, which is also where a
            // life can be bought with coins before hitting zero.
            return InkWell(
              onTap: () => showNoLivesDialog(context).then((_) => _refreshProgress()),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      livesState.canPlay ? Icons.favorite : Icons.heart_broken,
                      color: const Color(0xFFFF3366),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${livesState.count}/${PlayerLives.maxLives}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (countdown != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        formatLifeCountdown(countdown),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F5A0)),
                )
              : Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 4),
                    Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.draw, color: Color(0xFF00DDFF)),
            onPressed: () => context.push('/boards'),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
            onPressed: () => context.push('/leaderboard'),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1a1a2e),
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(LevelSummaryDTO level, int number, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.04);
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _playCurrentLevel(level, number),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F5A0),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('play'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('${l10n.translate('level')} $number', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

}
