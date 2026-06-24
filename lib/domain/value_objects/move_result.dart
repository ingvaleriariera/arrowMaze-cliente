import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';

class MoveResult {
  final bool success;
  final String arrowId;
  final List<ArrowSegment> exitedSegments;

  const MoveResult({
    required this.success,
    required this.arrowId,
    this.exitedSegments = const [],
  });

  static MoveResult exitSuccess(String arrowId, List<ArrowSegment> segments) =>
      MoveResult(
        success: true,
        arrowId: arrowId,
        exitedSegments: segments,
      );

  static MoveResult exitFailure(String arrowId) =>
      MoveResult(success: false, arrowId: arrowId);

  bool isSuccess() => success;

  @override
  String toString() =>
      'MoveResult(success: $success, arrowId: $arrowId, segments: ${exitedSegments.length})';
}
