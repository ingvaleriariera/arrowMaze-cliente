import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

/// A small, fixed set of avatar choices rather than a full emoji keyboard —
/// keeps the picker a simple grid instead of pulling in a picker package,
/// and stays consistent with the game's own colorful-arrow visual identity.
const _avatarChoices = [
  '🎮', '😀', '😎', '🤖', '👾', '🦊', '🐱', '🐶',
  '🦁', '🐼', '🐸', '🦄', '🌟', '🔥', '⚡', '🎯',
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  GameProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  Future<void> _loadProgress() async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return;

    final progress = await ref.read(getLocalProgressUseCaseProvider).execute(userId);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  Future<void> _chooseAvatar(String emoji) async {
    final progress = _progress;
    if (progress == null) return;

    progress.setAvatar(emoji);
    setState(() {});

    await ref.read(saveProgressUseCaseProvider).execute(progress);
    if (mounted) Navigator.of(context).pop();
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).translate('selectAvatar'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _avatarChoices.map((emoji) {
                return InkWell(
                  onTap: () => _chooseAvatar(emoji),
                  borderRadius: BorderRadius.circular(32),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0d0d18),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d18),
      appBar: AppBar(title: Text(l10n.translate('profile'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _openAvatarPicker,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 84,
                          backgroundColor: const Color(0xFF1a1a2e),
                          child: Text(_progress?.avatarEmoji ?? '🎮', style: const TextStyle(fontSize: 72)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF00F5A0),
                            child: const Icon(Icons.edit, size: 22, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    authState.username ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(
                        icon: Icons.check_circle,
                        label: l10n.translate('levelsCompleted'),
                        value: '${_progress?.completedLevels.length ?? 0}',
                      ),
                      _StatCard(
                        icon: Icons.star,
                        label: l10n.translate('totalScore'),
                        value: '${_progress?.totalScore ?? 0}',
                      ),
                      _StatCard(
                        icon: Icons.monetization_on,
                        label: l10n.translate('coins'),
                        value: '${_progress?.coins ?? 0}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00F5A0), size: 36),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}
