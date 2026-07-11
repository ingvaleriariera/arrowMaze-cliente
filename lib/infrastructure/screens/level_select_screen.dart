import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/bottom_tab_bar.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/no_lives_dialog.dart';

/// Only ask once per account whether to preload every level's board.
/// Scoped by userId so logging into a different account gets asked again.
String _askedPreloadAllPrefsKey(String userId) => 'asked_preload_all_$userId';

class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔧 LevelSelectScreen.initState: Initializing');
    
    // Load levels after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📋 LevelSelectScreen: Post-frame callback executing');
      
      final authState = ref.read(authNotifierProvider);
      final userId = authState.userId;
      
      if (userId != null) {
        debugPrint('🎯 LevelSelectScreen: userId=$userId, calling loadSummaries()');
        // Lives gate the level taps below; normally already loaded by
        // Home, but load here too so deep entries into this screen
        // (e.g. defeat -> back to levels) always have fresh state.
        ref.read(livesNotifierProvider.notifier).load(userId);
        ref.read(levelSelectNotifierProvider.notifier).loadSummaries(userId).then((_) {
          _maybeAskToPreloadAll(userId);
        });
      } else {
        debugPrint('⚠️  LevelSelectScreen: userId is null, not calling loadSummaries()');
      }
    });
  }

  Future<void> _maybeAskToPreloadAll(String userId) async {
    if (!mounted || ref.read(levelSelectNotifierProvider).levels.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _askedPreloadAllPrefsKey(userId);
    if (prefs.getBool(prefsKey) ?? false) return;
    await prefs.setBool(prefsKey, true);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(l10n.translate('preloadAllTitle')),
        content: Text(l10n.translate('preloadAllMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.translate('notNow')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.translate('downloadAll')),
          ),
        ],
      ),
    );

    if (accepted == true) {
      ref.read(levelSelectNotifierProvider.notifier).preloadAllLevels();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levelSelectState = ref.watch(levelSelectNotifierProvider);

    debugPrint('🎨 LevelSelectScreen.build: isLoading=${levelSelectState.isLoading}, levels=${levelSelectState.levels.length}');

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(l10n.translate('levelSelect'))),
          body: _buildBody(context, levelSelectState),
          // Settings/leaderboard/logout live only on Home now — Levels is
          // reachable straight from the tab bar, no need to duplicate them.
          bottomNavigationBar: const BottomTabBar(active: AppTab.levels),
        ),
        // Full-screen blocking overlay while every level's board is being
        // generated. Without this, tapping a level whose board hasn't
        // been preloaded yet starts a second generation that competes
        // with the batch still running, which is what made the game
        // screen itself feel stuck mid-play.
        if (levelSelectState.isPreloadingAll)
          _PreloadOverlay(
            completed: levelSelectState.preloadCompleted,
            total: levelSelectState.preloadTotal,
            progress: levelSelectState.preloadProgress,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, LevelSelectState state) {
    final l10n = AppLocalizations.of(context);
    debugPrint('🎨 LevelSelectScreen._buildBody: isLoading=${state.isLoading}, levels=${state.levels.length}');

    if (state.isLoading) {
      debugPrint('   → Showing spinner');
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
      );
    }

    if (state.error != null) {
      debugPrint('   → Showing error: ${state.error}');
      return Center(child: Text(state.error!));
    }

    if (state.levels.isEmpty) {
      debugPrint('   → No levels (empty list)');
      return Center(child: Text(l10n.translate('noLevelsAvailable')));
    }

    debugPrint('   → Showing ${state.levels.length} levels in grid');

    // DEBUG: Print the full list of levels as displayed
    debugPrint('📋 LEVEL LIST (UI order):');
    state.levels.asMap().forEach((index, summary) {
      debugPrint('   UI position $index → levelId=${summary.levelId} difficulty=${summary.difficulty}');
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.levels.length,
      itemBuilder: (context, index) {
        final level = state.levels[index];
        return GestureDetector(
          onTap: !level.unlocked || state.isPreloadingAll
              ? null
              : () {
                  debugPrint('👆 LevelSelectScreen: User tapped level: ${level.levelId}');

                  if (!ref.read(livesNotifierProvider).canPlay) {
                    showNoLivesDialog(context);
                    return;
                  }

                  // GameScreen.initState triggers the actual load for this levelId,
                  // so just navigate here to avoid a duplicate loadLevel() call.
                  debugPrint('   → Navigating to /game/${level.levelId}');
                  context.push(
                    '/game/${level.levelId}',
                    extra: {
                      'difficulty': level.difficulty,
                      // Community boards show their name; numbered levels
                      // their sequence position.
                      if (level.displayName != null)
                        'title': level.displayName
                      else
                        'levelNumber': index + 1,
                    },
                  );
                },
          child: Container(
            decoration: BoxDecoration(
              color: level.unlocked ? const Color(0xFF1a1a2e) : const Color(0xFF131320),
              border: Border.all(
                // Community boards get the cyan accent so they read as a
                // different "family" from the numbered progression.
                color: level.displayName != null
                    ? const Color(0xFF00DDFF)
                    : level.unlocked
                        ? const Color(0xFF00F5A0)
                        : const Color(0xFF333344),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (level.displayName != null) ...[
                  const Icon(Icons.draw, color: Color(0xFF00DDFF), size: 20),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      level.displayName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (level.completed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32)
                else
                  Text(
                    'Level ${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: level.unlocked ? null : const Color(0xFFFF3366),
                    ),
                  ),
                const SizedBox(height: 8),
                if (!level.unlocked)
                  const Icon(Icons.lock, color: Color(0xFF555566), size: 18)
                else if (level.displayName != null)
                  Text(level.difficulty, style: const TextStyle(fontSize: 11))
                else
                  Text(level.completed ? 'Score: ${level.bestScore}' : level.difficulty),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Opaque full-screen barrier with a determinate progress bar, shown
/// while every level is being preloaded. It both communicates real
/// progress and — via the outer GestureDetector swallowing taps — keeps
/// the player from opening a level until the batch finishes, since doing
/// so would start a second board generation competing with this one.
class _PreloadOverlay extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _PreloadOverlay({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Positioned.fill(
      child: GestureDetector(
        // Swallow every tap/drag so nothing underneath is reachable.
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: const Color(0xE6080812),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.translate('downloadingLevels'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total == 0 ? null : progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF1a1a2e),
                      color: const Color(0xFF00F5A0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completed/$total',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF888899)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
