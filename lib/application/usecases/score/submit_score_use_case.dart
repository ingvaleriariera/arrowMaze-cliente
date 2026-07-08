import 'package:arrow_maze_cliente_copy/application/ports/i_score_repository.dart';

class SubmitScoreUseCase {
  final IScoreRepository scoreRepository;

  SubmitScoreUseCase({required this.scoreRepository});

  Future<void> execute(String userId, String levelId, int score) async {
    return scoreRepository.submitScore(userId, levelId, score);
  }
}
