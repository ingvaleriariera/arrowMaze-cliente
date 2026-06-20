import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Pantalla de leaderboard — observa LeaderboardNotifier.
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String levelId;

  const LeaderboardScreen({super.key, required this.levelId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard(widget.levelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(leaderboardNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      appBar: AppBar(
        title: Text(
          'RANKING — ${widget.levelId.toUpperCase()}',
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF0F0F1E),
        leading: const BackButton(color: Color(0xFF00F5A0)),
      ),
      body: entries.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isTop3 = entry.rank <= 3;
                final rankColors = {
                  1: const Color(0xFFFFD700),
                  2: const Color(0xFFC0C0C0),
                  3: const Color(0xFFCD7F32),
                };
                final rankColor = rankColors[entry.rank] ?? const Color(0xFF555555);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTop3 ? rankColor.withAlpha(100) : const Color(0xFF1A1A2E),
                      width: isTop3 ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 36,
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Username
                      Expanded(
                        child: Text(
                          entry.username,
                          style: TextStyle(
                            color: isTop3 ? Colors.white : const Color(0xFFAAAAAA),
                            fontFamily: 'monospace',
                            fontWeight: isTop3 ? FontWeight.w700 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Score
                      Text(
                        '${entry.score}',
                        style: TextStyle(
                          color: isTop3 ? rankColor : const Color(0xFF00F5A0),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
