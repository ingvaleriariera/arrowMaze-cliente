import '../entities/arrow.dart';
import '../entities/board.dart';
import '../value_objects/board_shape.dart';

class BoardBuilder {
  BoardShape? shape;
  final List<Arrow> arrows = [];

  BoardBuilder._();

  static BoardBuilder create() => BoardBuilder._();

  BoardBuilder setShape(BoardShape shape) {
    this.shape = shape;
    return this;
  }

  BoardBuilder addArrow(Arrow arrow) {
    arrows.add(arrow);
    return this;
  }

  Board build() {
    final boardShape = shape;
    if (boardShape == null) {
      throw StateError('BoardShape must be set before building a Board');
    }
    final arrowMap = <String, Arrow>{
      for (final arrow in arrows) arrow.getId(): arrow,
    };
    return Board(boardShape, arrowMap);
  }
}
