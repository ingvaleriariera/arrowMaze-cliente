import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_score_repository.dart';

class ScoreRepositoryImpl implements IScoreRepository {
  final ApiClient apiClient;

  ScoreRepositoryImpl({required this.apiClient});

  @override
  Future<void> submitScore(String userId, String levelId, int score) async {
    await apiClient.post('/api/v1/scores/submit', {
      'userId': userId,
      'levelId': levelId,
      'score': score,
    });
  }
}
