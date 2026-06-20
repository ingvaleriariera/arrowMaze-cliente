import 'package:flutter_riverpod/legacy.dart';

import '../../application/dtos/level_summary_dto.dart';
import '../../application/use_cases/game/get_level_summaries_use_case.dart';

class LevelSelectNotifier extends StateNotifier<List<LevelSummaryDTO>> {
  final GetLevelSummariesUseCase getLevelSummariesUseCase;

  LevelSelectNotifier(this.getLevelSummariesUseCase) : super(const []);

  Future<void> loadSummaries(String userId) async {
    state = await getLevelSummariesUseCase.execute(userId);
  }

  List<LevelSummaryDTO> getLevels() => state;
}
