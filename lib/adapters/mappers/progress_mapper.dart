import 'dart:convert';

import '../../domain/entities/game_progress.dart';

class ProgressMapper {
  GameProgress fromMap(Map<String, dynamic> map) {
    final completedLevels =
        (jsonDecode(map['completedLevels'] as String) as List<dynamic>).cast<String>();
    final bestScores = (jsonDecode(map['bestScores'] as String) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as int));

    return GameProgress(
      map['userId'] as String,
      completedLevels,
      bestScores,
      map['coins'] as int,
    );
  }

  Map<String, dynamic> toMap(GameProgress progress) {
    return {
      'userId': progress.userId,
      'completedLevels': jsonEncode(progress.completedLevels),
      'bestScores': jsonEncode(progress.bestScores),
      'coins': progress.coins,
    };
  }
}
