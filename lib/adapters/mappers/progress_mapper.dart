import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';

class ProgressMapper {
  GameProgress fromMap(Map<String, dynamic> map, {required String userId}) {
    debugPrint('📍 ProgressMapper.fromMap: Parsing progress for userId=$userId');
    
    try {
      final completedLevels = <String>[];
      final bestScores = <String, int>{};

      // Parse "levels" array from backend response
      final levelsList = map['levels'] as List<dynamic>? ?? [];
      debugPrint('   Parsing ${levelsList.length} levels from response');

      for (final levelData in levelsList) {
        final levelMap = levelData as Map<String, dynamic>? ?? {};
        
        final levelId = levelMap['levelId'] as String? ?? '';
        final bestScore = levelMap['bestScore'] as int? ?? 0;
        
        if (levelId.isNotEmpty) {
          debugPrint('   - $levelId: bestScore=$bestScore');
          
          // Add to bestScores map
          bestScores[levelId] = bestScore;
          
          // Add to completedLevels if score > 0
          if (bestScore > 0) {
            completedLevels.add(levelId);
          }
        }
      }

      debugPrint('✅ ProgressMapper: Parsed ${completedLevels.length} completed levels, ${bestScores.length} total scores');

      return GameProgress(
        userId: userId,
        completedLevels: completedLevels,
        bestScores: bestScores,
        coins: map['coins'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ProgressMapper.fromMap: Error parsing - $e');
      debugPrint('   StackTrace: $stackTrace');
      
      // Return empty progress on parse error
      debugPrint('   Returning empty progress as fallback');
      return GameProgress(userId: userId);
    }
  }

  Map<String, dynamic> toMap(GameProgress progress) {
    debugPrint('📍 ProgressMapper.toMap: Converting progress for userId=${progress.userId}');
    debugPrint('   ${progress.completedLevels.length} completed, ${progress.bestScores.length} scores');

    final levelsList = <Map<String, dynamic>>[];
    
    for (final entry in progress.bestScores.entries) {
      levelsList.add({
        'levelId': entry.key,
        'bestScore': entry.value,
        'completedAt': DateTime.now().toIso8601String(),
      });
    }

    return {
      'levels': levelsList,
    };
  }
}
