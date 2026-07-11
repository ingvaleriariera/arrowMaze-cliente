import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/custom_aware_level_repository.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_shape_preview.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/no_lives_dialog.dart';

/// Community boards browser: "Comunidad" lists everyone's published
/// boards (cheap dot previews, no arrows) to adopt; "Míos" lists the
/// adopted ones, playable through the normal game pipeline via the
/// custom- level id prefix.
class BoardsScreen extends ConsumerStatefulWidget {
  const BoardsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boardsNotifierProvider.notifier).loadAll();
    });
  }

  void _play(CustomBoardDTO board) {
    if (!ref.read(livesNotifierProvider).canPlay) {
      showNoLivesDialog(context);
      return;
    }
    context.push(
      '/game/${CustomAwareLevelRepository.levelIdFor(board.id)}',
      extra: {
        'difficulty': board.difficulty,
        'title': board.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(boardsNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0d0d18),
        appBar: AppBar(
          title: Text(l10n.translate('playerBoards')),
          bottom: TabBar(
            indicatorColor: const Color(0xFF00F5A0),
            labelColor: const Color(0xFF00F5A0),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: l10n.translate('communityBoards')),
              Tab(text: l10n.translate('myBoards')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/boards/editor'),
          backgroundColor: const Color(0xFF00F5A0),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.draw),
          label: Text(l10n.translate('createBoard')),
        ),
        body: TabBarView(
          children: [
            _buildCommunityTab(l10n, state),
            _buildMineTab(l10n, state),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityTab(AppLocalizations l10n, dynamic state) {
    if (state.isLoadingCommunity) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00F5A0)));
    }
    if (state.error != null && state.community.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(boardsNotifierProvider.notifier).loadAll(),
              child: Text(l10n.translate('retry')),
            ),
          ],
        ),
      );
    }
    if (state.community.isEmpty) {
      return Center(child: Text(l10n.translate('noCommunityBoards')));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: state.community.length as int,
      itemBuilder: (context, index) {
        final board = state.community[index] as CustomBoardDTO;
        final added = state.isAdded(board.id) as bool;
        return _boardCard(
          l10n,
          board,
          trailing: added
              ? const Icon(Icons.check_circle, color: Color(0xFF00F5A0))
              : ElevatedButton(
                  onPressed: () =>
                      ref.read(boardsNotifierProvider.notifier).adopt(board),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(l10n.translate('addBoard')),
                ),
          onTap: added ? () => _play(board) : null,
        );
      },
    );
  }

  Widget _buildMineTab(AppLocalizations l10n, dynamic state) {
    if (state.mine.isEmpty) {
      return Center(child: Text(l10n.translate('noMyBoards')));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: state.mine.length as int,
      itemBuilder: (context, index) {
        final board = state.mine[index] as CustomBoardDTO;
        return _boardCard(
          l10n,
          board,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white38),
                onPressed: () => ref
                    .read(boardsNotifierProvider.notifier)
                    .removeFromMine(board.id),
              ),
              const Icon(Icons.play_circle_fill,
                  color: Color(0xFF00F5A0), size: 34),
            ],
          ),
          onTap: () => _play(board),
        );
      },
    );
  }

  Widget _boardCard(
    AppLocalizations l10n,
    CustomBoardDTO board, {
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: const Color(0xFF1a1a2e),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BoardShapePreview(grid: board.decodeGrid()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('byAuthor')} ${board.authorUsername} · ${l10n.translate(board.difficulty)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
