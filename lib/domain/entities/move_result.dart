import 'arrow_segment.dart';

class MoveResult {
  final bool _success;
  final String arrowId;
  final List<ArrowSegment> exitedSegments;

  MoveResult._(this._success, this.arrowId, this.exitedSegments);

  static MoveResult success(String arrowId, List<ArrowSegment> segments) =>
      MoveResult._(true, arrowId, segments);

  static MoveResult failure(String arrowId) =>
      MoveResult._(false, arrowId, const []);

  bool isSuccess() => _success;
  String getArrowId() => arrowId;
  List<ArrowSegment> getExitedSegments() => exitedSegments;
}
