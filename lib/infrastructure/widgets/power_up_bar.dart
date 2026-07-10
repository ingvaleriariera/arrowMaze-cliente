import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

/// Static description of one power-up button, purely presentational — the
/// actual purchase/use logic lives in GameScreen via [onSelect].
class _PowerUpInfo {
  final String type;
  final IconData icon;
  final String labelKey;
  final int cost;
  final String descriptionKey;

  const _PowerUpInfo({
    required this.type,
    required this.icon,
    required this.labelKey,
    required this.cost,
    required this.descriptionKey,
  });
}

const _powerUps = [
  _PowerUpInfo(
    type: 'HINT',
    icon: Icons.lightbulb,
    labelKey: 'hintName',
    cost: 100,
    descriptionKey: 'hintDescription',
  ),
  _PowerUpInfo(
    type: 'GRID',
    icon: Icons.grid_view,
    labelKey: 'gridName',
    cost: 50,
    descriptionKey: 'gridDescription',
  ),
  _PowerUpInfo(
    type: 'HAMMER',
    icon: Icons.construction,
    labelKey: 'hammerName',
    cost: 100,
    descriptionKey: 'hammerDescription',
  ),
  _PowerUpInfo(
    type: 'MAGNET',
    icon: Icons.control_camera,
    labelKey: 'magnetName',
    cost: 500,
    descriptionKey: 'magnetDescription',
  ),
];

/// The 4-button power-up row shown below the board. Tapping a button shows
/// what it does and its cost; confirming there is what actually triggers
/// [onSelect] — the bar itself never spends coins or touches the board.
class PowerUpBar extends StatelessWidget {
  final int coins;
  final String? pendingType;
  final void Function(String type) onSelect;

  const PowerUpBar({
    required this.coins,
    required this.onSelect,
    this.pendingType,
    super.key,
  });

  String _getPowerUpLabel(BuildContext context, String labelKey) {
    final l10n = AppLocalizations.of(context);
    return l10n.translate(labelKey);
  }

  String _getPowerUpDescription(BuildContext context, String descriptionKey) {
    final l10n = AppLocalizations.of(context);
    return l10n.translate(descriptionKey);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1a1a2e),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 4),
              Text('$coins',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _powerUps.map((info) {
              return _PowerUpButton(
                info: info,
                affordable: coins >= info.cost,
                active: pendingType == info.type,
                onTap: () => _showInfoSheet(context, info),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, _PowerUpInfo info) {
    final l10n = AppLocalizations.of(context);
    final affordable = coins >= info.cost;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, color: const Color(0xFF00F5A0), size: 40),
            const SizedBox(height: 12),
            Text(l10n.translate(info.labelKey),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.translate(info.descriptionKey),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: affordable
                  ? () {
                      Navigator.of(ctx).pop();
                      onSelect(info.type);
                    }
                  : null,
              icon: const Icon(Icons.monetization_on, color: Colors.black),
              label: Text('${info.cost}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            if (!affordable) ...[
              const SizedBox(height: 8),
              Text(l10n.translate('notEnoughCoins'),
                  style: const TextStyle(color: Color(0xFFFF3366), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final _PowerUpInfo info;
  final bool affordable;
  final bool active;
  final VoidCallback onTap;

  const _PowerUpButton({
    required this.info,
    required this.affordable,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00F5A0).withValues(alpha: 0.25)
              : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0xFF00F5A0) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon,
                color: affordable ? const Color(0xFF00F5A0) : Colors.grey,
                size: 26),
            const SizedBox(height: 4),
            Text(l10n.translate(info.labelKey),
                style: TextStyle(
                    color: affordable ? Colors.white : Colors.grey,
                    fontSize: 11)),
            Text('${info.cost}',
                style: TextStyle(
                    color:
                        affordable ? const Color(0xFFFFD700) : Colors.grey,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
