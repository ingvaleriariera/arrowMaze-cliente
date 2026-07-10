import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/leaderboard_state.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

/// A leaderboard row reduced to just what the UI needs to render it — lets
/// the podium/list widgets below stay agnostic of whether they're showing
/// LeaderboardEntryDTO (per-level, field `score`) or
/// GlobalLeaderboardEntryDTO (field `totalScore`), instead of duplicating
/// the same layout twice.
class _DisplayEntry {
  final int rank;
  final String username;
  final int score;

  const _DisplayEntry({required this.rank, required this.username, required this.score});
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedLevelId;
  List<String> _availableLevelIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLevelsAndLeaderboard();
    });
  }

  void _loadLevelsAndLeaderboard() async {
    final levelRepo = ref.read(levelRepositoryProvider);
    try {
      final levels = await levelRepo.getLevels();
      if (levels.isNotEmpty) {
        final levelIds = levels.map((l) => l.id).toList();
        setState(() {
          _availableLevelIds = levelIds;
          _selectedLevelId = levelIds.first;
        });

        final leaderboardNotifier = ref.read(leaderboardNotifierProvider.notifier);
        leaderboardNotifier.loadLeaderboard(_selectedLevelId!);
      }
    } catch (e) {
      debugPrint('Error loading levels: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final leaderboardState = ref.watch(leaderboardNotifierProvider);
    final leaderboardNotifier = ref.read(leaderboardNotifierProvider.notifier);
    final isGlobal = leaderboardState.mode == LeaderboardMode.global;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('leaderboard'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<LeaderboardMode>(
                  segments: [
                    ButtonSegment(
                      value: LeaderboardMode.perLevel,
                      label: Text(l10n.translate('perLevel')),
                    ),
                    ButtonSegment(
                      value: LeaderboardMode.global,
                      label: Text(l10n.translate('globalLeaderboard')),
                    ),
                  ],
                  selected: {leaderboardState.mode},
                  onSelectionChanged: (selection) {
                    final mode = selection.first;
                    if (mode == LeaderboardMode.global) {
                      leaderboardNotifier.loadGlobalLeaderboard();
                    } else if (_selectedLevelId != null) {
                      leaderboardNotifier.loadLeaderboard(_selectedLevelId!);
                    }
                  },
                ),
                if (!isGlobal) ...[
                  const SizedBox(height: 12),
                  _availableLevelIds.isEmpty
                      ? Text(l10n.translate('loadingLevels'))
                      : DropdownButton<String>(
                          value: _selectedLevelId,
                          items: _availableLevelIds.asMap().entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.value,
                              child: Text('Level ${entry.key + 1}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLevelId = value);
                              leaderboardNotifier.loadLeaderboard(value);
                            }
                          },
                        ),
                ],
              ],
            ),
          ),
          Expanded(
            child: leaderboardState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
                : leaderboardState.error != null
                    ? Center(child: Text(leaderboardState.error!))
                    : _buildLeaderboardBody(
                        isGlobal
                            ? leaderboardState.globalEntries
                                .map((e) => _DisplayEntry(rank: e.rank, username: e.username, score: e.totalScore))
                                .toList()
                            : leaderboardState.entries
                                .map((e) => _DisplayEntry(rank: e.rank, username: e.username, score: e.score))
                                .toList(),
                        l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardBody(List<_DisplayEntry> entries, AppLocalizations l10n) {
    if (entries.isEmpty) {
      return Center(child: Text(l10n.translate('noLeaderboardData')));
    }

    final podium = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      children: [
        if (podium.isNotEmpty) _buildPodium(podium),
        ...rest.map((entry) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(entry.rank),
                child: Text('${entry.rank}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(entry.username),
              trailing: Text('${entry.score}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }

  /// Classic 2nd-1st-3rd podium layout: rank 1 tallest and centered, 2 and
  /// 3 flanking it shorter — only drawn for however many of the top 3
  /// actually exist (a level with 1-2 players still gets a partial podium).
  Widget _buildPodium(List<_DisplayEntry> top3) {
    _DisplayEntry? at(int rank) {
      for (final e in top3) {
        if (e.rank == rank) return e;
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (at(2) != null) Expanded(child: _podiumCard(at(2)!, height: 110, avatarRadius: 26)),
          if (at(1) != null) Expanded(child: _podiumCard(at(1)!, height: 140, avatarRadius: 34)),
          if (at(3) != null) Expanded(child: _podiumCard(at(3)!, height: 90, avatarRadius: 22)),
        ],
      ),
    );
  }

  Widget _podiumCard(_DisplayEntry entry, {required double height, required double avatarRadius}) {
    final color = _getRankColor(entry.rank);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.rank == 1) const Text('👑', style: TextStyle(fontSize: 22)),
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: color,
            child: Text('${entry.rank}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: avatarRadius * 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text('${entry.score}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              border: Border.all(color: color, width: 2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.blue;
    }
  }
}
