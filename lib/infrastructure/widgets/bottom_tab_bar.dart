import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

enum AppTab { home, levels }

/// Shared bottom tab bar for the two "root" screens (Home/Levels) —
/// switching between them replaces the stack (go, not push), same as
/// tapping a tab shouldn't grow browser-style history.
class BottomTabBar extends StatelessWidget {
  final AppTab active;

  const BottomTabBar({required this.active, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Color(0xFF252535), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TabButton(
              icon: Icons.home,
              label: l10n.translate('home'),
              active: active == AppTab.home,
              onTap: active == AppTab.home ? null : () => context.go('/home'),
            ),
            _TabButton(
              icon: Icons.grid_view,
              label: l10n.translate('levelSelect'),
              active: active == AppTab.levels,
              onTap: active == AppTab.levels ? null : () => context.go('/levels'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _TabButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00F5A0) : Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
