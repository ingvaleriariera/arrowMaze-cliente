import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class GetLevelSummariesUseCase {
  final ILevelRepository levelRepository;
  final IGameProgressRepository progressRepository;

  GetLevelSummariesUseCase({
    required this.levelRepository,
    required this.progressRepository,
  });

  Future<List<LevelSummaryDTO>> execute(String userId) async {
    final levels = await levelRepository.getLevels();
    final progress = await progressRepository.get(userId);

    final summaries = <LevelSummaryDTO>[];

    for (final level in levels) {
      final isCompleted = progress?.isCompleted(level.id) ?? false;
      final bestScore = progress?.getBestScore(level.id) ?? 0;

      summaries.add(
        LevelSummaryDTO(
          levelId: level.id,
          difficulty: level.difficulty,
          completed: isCompleted,
          bestScore: bestScore,
          isTimed: level.isTimed(),
        ),
      );
    }

    return summaries;
  }
}
