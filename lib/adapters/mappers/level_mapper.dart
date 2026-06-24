import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

class LevelMapper {
  Level fromJson(Map<String, dynamic> json) {
    debugPrint('📍 LevelMapper.fromJson: Processing level ${json['id']}');
    
    try {
      final timeSeconds = json['timeLimitSeconds'] as int?;
      final timeLimit = timeSeconds != null && timeSeconds > 0
          ? TimeLimit.of(timeSeconds)
          : TimeLimit.none;

      // Handle boardLayout - can be string or object
      String boardLayout = '';
      final layoutData = json['boardLayout'];
      if (layoutData is String) {
        boardLayout = layoutData;
        debugPrint('   boardLayout is String: $boardLayout');
      } else if (layoutData is Map || layoutData is List) {
        boardLayout = jsonEncode(layoutData);
        debugPrint('   boardLayout is Map/List, encoded to: $boardLayout');
      } else {
        debugPrint('   boardLayout has unexpected type: ${layoutData.runtimeType}');
        boardLayout = '[[]]'; // Default empty board
      }

      final level = Level(
        id: json['id'] as String,
        difficulty: json['difficulty'] as String,
        boardLayout: boardLayout,
        moveLimit: json['moveLimit'] as int,
        timeLimit: timeLimit,
      );
      
      debugPrint('✅ LevelMapper: Successfully created Level(id=${level.id}, difficulty=${level.difficulty})');
      return level;
    } catch (e, stackTrace) {
      debugPrint('❌ LevelMapper.fromJson: Error processing level');
      debugPrint('   Exception: $e');
      debugPrint('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  List<Level> fromJsonList(List<dynamic> jsonList) {
    debugPrint('📍 LevelMapper.fromJsonList: Processing ${jsonList.length} levels');
    
    try {
      final levels = jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      debugPrint('✅ LevelMapper: Successfully processed ${levels.length} levels');
      return levels;
    } catch (e, stackTrace) {
      debugPrint('❌ LevelMapper.fromJsonList: Error processing list');
      debugPrint('   Exception: $e');
      debugPrint('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Arrow arrowFromJson(Map<String, dynamic> json) {
    final segments = <ArrowSegment>[];
    final positionList = json['cells'] as List<dynamic>? ?? [];
    final dirHex = json['color'] as String;

    for (int i = 0; i < positionList.length; i++) {
      final pos = positionList[i] as Map<String, dynamic>;
      final x = pos['x'] as int;
      final y = pos['y'] as int;
      final position = Position(x, y);

      // Direction for the segment (all segments point in the arrow's direction)
      final direction = _parseDirection(json['direction'] as String);

      segments.add(ArrowSegment(
        position: position,
        directionToNext: direction,
      ));
    }

    return Arrow(
      id: json['id'] as String,
      segments: segments,
      color: ArrowColor.fromHex(dirHex),
    );
  }

  Direction _parseDirection(String directionStr) {
    switch (directionStr.toUpperCase()) {
      case 'UP':
        return Direction.up;
      case 'DOWN':
        return Direction.down;
      case 'LEFT':
        return Direction.left;
      case 'RIGHT':
        return Direction.right;
      default:
        return Direction.right;
    }
  }
}
