import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';

abstract class IGameProgressRepository {
  Future<void> save(GameProgress progress);
  Future<GameProgress?> get(String userId);
  Future<GameProgress> sync(String userId);
}
