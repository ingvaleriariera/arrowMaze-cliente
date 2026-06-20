import '../value_objects/arrow_color.dart';
import '../value_objects/direction.dart';
import 'arrow_segment.dart';

class Arrow {
  final String id;
  final List<ArrowSegment> segments;
  final ArrowColor color;

  Arrow(this.id, this.segments, this.color);

  String getId() => id;
  ArrowSegment getHead() => segments.first;
  Direction getDirection() => getHead().getDirectionToNext();
  List<ArrowSegment> getSegments() => segments;
  ArrowColor getColor() => color;
}
