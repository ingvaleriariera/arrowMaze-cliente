import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';

class ProgressMapper {
  GameProgress fromMap(Map<String, dynamic> map) {
    final completedList = map['completedLevels'] as List<dynamic>? ?? [];
    final scoresMap = (map['bestScores'] as Map<String, dynamic>?) ?? {};

    return GameProgress(
      userId: map['userId'] as String,
      completedLevels: completedList.cast<String>(),
      bestScores: scoresMap.cast<String, int>(),
      coins: map['coins'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap(GameProgress progress) {
    return {
      'userId': progress.userId,
      'completedLevels': progress.completedLevels,
      'bestScores': progress.bestScores,
      'coins': progress.coins,
    };
  }
}
