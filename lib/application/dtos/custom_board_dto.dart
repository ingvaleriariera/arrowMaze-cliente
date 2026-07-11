import 'dart:convert';

/// A player-designed board shape, as served by the backend's
/// custom-boards endpoints. Only the SHAPE travels (0/1 grid, same wire
/// format as standard levels' boardLayout) — arrows are generated
/// client-side from a deterministic per-board seed, like any level.
class CustomBoardDTO {
  final String id;
  final String name;
  final String authorId;
  final String authorUsername;
  final String difficulty;
  final String boardLayout;
  final String createdAt;

  const CustomBoardDTO({
    required this.id,
    required this.name,
    this.authorId = '',
    required this.authorUsername,
    required this.difficulty,
    required this.boardLayout,
    required this.createdAt,
  });

  factory CustomBoardDTO.fromJson(Map<String, dynamic> json) => CustomBoardDTO(
        id: json['id'] as String,
        name: json['name'] as String,
        authorId: json['authorId'] as String? ?? '',
        authorUsername: json['authorUsername'] as String? ?? 'Unknown',
        difficulty: json['difficulty'] as String,
        boardLayout: json['boardLayout'] as String,
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'authorId': authorId,
        'authorUsername': authorUsername,
        'difficulty': difficulty,
        'boardLayout': boardLayout,
        'createdAt': createdAt,
      };

  /// The 0/1 grid decoded from [boardLayout] — used by previews and the
  /// editor; returns an empty grid on malformed data instead of throwing.
  List<List<int>> decodeGrid() {
    try {
      final map = jsonDecode(boardLayout) as Map<String, dynamic>;
      final rows = map['grid'] as List<dynamic>;
      return rows
          .map((row) => (row as List<dynamic>).map((c) => c as int).toList())
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
