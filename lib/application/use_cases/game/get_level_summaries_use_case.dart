import '../../../domain/ports/i_game_progress_repository.dart';
import '../../../domain/ports/i_level_repository.dart';
import '../../dtos/level_summary_dto.dart';

class GetLevelSummariesUseCase {
  final ILevelRepository levelRepository;
  final IGameProgressRepository progressRepository;

  GetLevelSummariesUseCase(this.levelRepository, this.progressRepository);

  Future<List<LevelSummaryDTO>> execute(String userId) async {
    final levels = await levelRepository.getLevels();
    final progress = await progressRepository.get(userId);

    return levels.map((level) {
      final levelId = level.getId();
      return LevelSummaryDTO(
        levelId,
        level.getDifficulty(),
        progress?.isCompleted(levelId) ?? false,
        progress?.getBestScore(levelId) ?? 0,
        level.isTimed(),
      );
    }).toList();
  }
}
