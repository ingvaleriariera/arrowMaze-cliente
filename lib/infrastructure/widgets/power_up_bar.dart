import 'package:flutter/material.dart';

/// Static description of one power-up button, purely presentational — the
/// actual purchase/use logic lives in GameScreen via [onSelect].
class _PowerUpInfo {
  final String type;
  final IconData icon;
  final String label;
  final int cost;
  final String description;

  const _PowerUpInfo({
    required this.type,
    required this.icon,
    required this.label,
    required this.cost,
    required this.description,
  });
}

const _powerUps = [
  _PowerUpInfo(
    type: 'HINT',
    icon: Icons.lightbulb,
    label: 'Pista',
    cost: 100,
    description: 'Resalta una flecha que puede salir ahora mismo.',
  ),
  _PowerUpInfo(
    type: 'GRID',
    icon: Icons.grid_view,
    label: 'Cuadrícula',
    cost: 50,
    description: 'Muestra hacia dónde sale cada flecha del tablero.',
  ),
  _PowerUpInfo(
    type: 'HAMMER',
    icon: Icons.construction,
    label: 'Martillo',
    cost: 100,
    description: 'Toca cualquier flecha del tablero para destruirla, '
        'incluso si está bloqueada.',
  ),
  _PowerUpInfo(
    type: 'MAGNET',
    icon: Icons.control_camera,
    label: 'Imán',
    cost: 500,
    description: 'Elimina hasta 5 flechas que ya pueden salir del tablero.',
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
            Text(info.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(info.description,
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
              const Text('No tienes suficientes monedas',
                  style: TextStyle(color: Color(0xFFFF3366), fontSize: 12)),
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
            Text(info.label,
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
