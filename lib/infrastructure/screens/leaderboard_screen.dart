import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('leaderboard'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _availableLevelIds.isEmpty
                ? const Text('Loading levels...')
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
                        final leaderboardNotifier = ref.read(leaderboardNotifierProvider.notifier);
                        leaderboardNotifier.loadLeaderboard(value);
                      }
                    },
                  ),
          ),
          Expanded(
            child: leaderboardState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
                : leaderboardState.error != null
                    ? Center(child: Text(leaderboardState.error!))
                    : leaderboardState.entries.isEmpty
                        ? const Center(child: Text('No leaderboard data'))
                        : ListView.builder(
                            itemCount: leaderboardState.entries.length,
                            itemBuilder: (context, index) {
                              final entry = leaderboardState.entries[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRankColor(entry.rank),
                                  child: Text(
                                    '${entry.rank}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(entry.username),
                                trailing: Text('${entry.score}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              );
                            },
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
