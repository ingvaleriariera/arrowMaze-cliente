import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

/// Canvas-of-dots board designer: pick a size, then tap/drag cells to
/// "draw" the shape (bright = playable 1, gray = empty 0), name it, pick
/// a difficulty and publish it to the community.
class BoardEditorScreen extends ConsumerStatefulWidget {
  const BoardEditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BoardEditorScreen> createState() => _BoardEditorScreenState();
}

class _BoardEditorScreenState extends ConsumerState<BoardEditorScreen> {
  /// Mirrors the backend's CustomBoard.minActiveCells domain rule so the
  /// user gets feedback before a round-trip.
  static const int _minActiveCells = 10;

  List<List<int>>? _grid;
  String _difficulty = 'medium';
  final _nameController = TextEditingController();

  /// While dragging, every touched cell is set to this value — decided by
  /// the first cell the drag lands on, so a stroke paints OR erases
  /// consistently instead of flickering cells on and off as it crosses.
  int? _paintValue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _activeCells =>
      _grid?.fold<int>(0, (sum, row) => sum + row.where((c) => c == 1).length) ?? 0;

  void _startGrid(int side) {
    setState(() {
      _grid = List.generate(side, (_) => List.filled(side, 0));
    });
  }

  void _applyAt(Offset localPosition, double cellSize, {required bool isDragStart, required bool isTap}) {
    final grid = _grid;
    if (grid == null) return;
    final x = (localPosition.dx / cellSize).floor();
    final y = (localPosition.dy / cellSize).floor();
    if (y < 0 || y >= grid.length || x < 0 || x >= grid[y].length) return;

    setState(() {
      if (isTap) {
        grid[y][x] = grid[y][x] == 1 ? 0 : 1;
      } else {
        if (isDragStart) _paintValue = grid[y][x] == 1 ? 0 : 1;
        final value = _paintValue;
        if (value != null) grid[y][x] = value;
      }
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    final grid = _grid;
    if (grid == null) return;

    if (_activeCells < _minActiveCells) {
      _showSnack(l10n.translate('boardTooSmall'));
      return;
    }
    if (_nameController.text.trim().length < 3) {
      _showSnack(l10n.translate('boardNameTooShort'));
      return;
    }

    final ok = await ref.read(boardsNotifierProvider.notifier).create(
          name: _nameController.text.trim(),
          difficulty: _difficulty,
          grid: grid,
        );

    if (!mounted) return;
    if (ok) {
      _showSnack(l10n.translate('boardSaved'));
      context.pop();
    } else {
      _showSnack(ref.read(boardsNotifierProvider).error ??
          l10n.translate('boardSaveFailed'));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSaving = ref.watch(boardsNotifierProvider.select((s) => s.isSaving));

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d18),
      appBar: AppBar(title: Text(l10n.translate('createBoard'))),
      body: _grid == null ? _buildSizePicker(l10n) : _buildEditor(l10n, isSaving),
    );
  }

  Widget _buildSizePicker(AppLocalizations l10n) {
    Widget option(String label, String subtitle, int side) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startGrid(side),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a2e),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF00F5A0), width: 1),
              ),
            ),
            child: Column(
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.translate('chooseSize'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          option(l10n.translate('sizeSmall'), '8×8 · ~15 ${l10n.translate('arrows')}', 8),
          option(l10n.translate('sizeMedium'), '12×12 · ~40 ${l10n.translate('arrows')}', 12),
          option(l10n.translate('sizeLarge'), '16×16 · ~80 ${l10n.translate('arrows')}', 16),
        ],
      ),
    );
  }

  Widget _buildEditor(AppLocalizations l10n, bool isSaving) {
    final grid = _grid!;
    final side = grid.length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.translate('drawHint'),
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                Text(
                  '$_activeCells ${l10n.translate('cells')}',
                  style: TextStyle(
                    color: _activeCells >= _minActiveCells
                        ? const Color(0xFF00F5A0)
                        : const Color(0xFFFF3366),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSide = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  final cellSize = (boardSide - 24) / side;
                  final canvasSide = cellSize * side;

                  return GestureDetector(
                    onTapDown: (d) => _applyAt(d.localPosition, cellSize,
                        isDragStart: false, isTap: true),
                    onPanStart: (d) => _applyAt(d.localPosition, cellSize,
                        isDragStart: true, isTap: false),
                    onPanUpdate: (d) => _applyAt(d.localPosition, cellSize,
                        isDragStart: false, isTap: false),
                    onPanEnd: (_) => _paintValue = null,
                    child: SizedBox(
                      width: canvasSide,
                      height: canvasSide,
                      child: CustomPaint(
                        painter: _EditorGridPainter(grid: grid, cellSize: cellSize),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: l10n.translate('boardName'),
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'easy', label: Text(l10n.translate('easy'))),
                    ButtonSegment(value: 'medium', label: Text(l10n.translate('medium'))),
                    ButtonSegment(value: 'hard', label: Text(l10n.translate('hard'))),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) =>
                      setState(() => _difficulty = selection.first),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => _save(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5A0),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(l10n.translate('publishBoard')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorGridPainter extends CustomPainter {
  final List<List<int>> grid;
  final double cellSize;

  _EditorGridPainter({required this.grid, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()..color = const Color(0xFF00F5A0);
    final activeBorder = Paint()
      ..color = const Color(0xFF00B87A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = const Color(0xFF33334A);

    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final cx = (x + 0.5) * cellSize;
        final cy = (y + 0.5) * cellSize;
        if (grid[y][x] == 1) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy),
                width: cellSize * 0.86,
                height: cellSize * 0.86),
            Radius.circular(cellSize * 0.18),
          );
          canvas.drawRRect(rect, activePaint);
          canvas.drawRRect(rect, activeBorder);
        } else {
          canvas.drawCircle(Offset(cx, cy), cellSize * 0.10, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_EditorGridPainter oldDelegate) => true;
}
