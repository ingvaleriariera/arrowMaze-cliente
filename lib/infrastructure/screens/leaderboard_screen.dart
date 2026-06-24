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
  String _selectedLevelId = 'level_001';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    final leaderboardNotifier = ref.read(leaderboardNotifierProvider.notifier);
    leaderboardNotifier.loadLeaderboard(_selectedLevelId);
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
            child: DropdownButton<String>(
              value: _selectedLevelId,
              items: [
                DropdownMenuItem(value: 'level_001', child: const Text('Level 1')),
                DropdownMenuItem(value: 'level_002', child: const Text('Level 2')),
              ],
              onChanged: (value) {
                setState(() => _selectedLevelId = value!);
                _loadLeaderboard();
              },
            ),
          ),
          Expanded(
            child: leaderboardState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
                : leaderboardState.error != null
                    ? Center(child: Text(leaderboardState.error!))
                    : ListView.builder(
                        itemCount: leaderboardState.entries.length,
                        itemBuilder: (context, index) {
                          final entry = leaderboardState.entries[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${entry.rank}'),
                            ),
                            title: Text(entry.username),
                            trailing: Text('${entry.score}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
