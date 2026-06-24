import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

void main() {
  group('Value Objects', () {
    group('Direction', () {
      test('Factory constructors create correct directions', () {
        expect(Direction.up.dx, equals(0));
        expect(Direction.up.dy, equals(-1));

        expect(Direction.down.dx, equals(0));
        expect(Direction.down.dy, equals(1));

        expect(Direction.left.dx, equals(-1));
        expect(Direction.left.dy, equals(0));

        expect(Direction.right.dx, equals(1));
        expect(Direction.right.dy, equals(0));
      });

      test('Opposite direction is correct', () {
        expect(Direction.up.opposite(), equals(Direction.down));
        expect(Direction.down.opposite(), equals(Direction.up));
        expect(Direction.left.opposite(), equals(Direction.right));
        expect(Direction.right.opposite(), equals(Direction.left));
      });

      test('Direction equality works', () {
        expect(Direction.up, equals(Direction.up));
        expect(Direction.up, isNot(equals(Direction.down)));
      });

      test('Direction hashCode is consistent', () {
        expect(Direction.up.hashCode, equals(Direction.up.hashCode));
        expect(Direction.up.hashCode, isNot(equals(Direction.down.hashCode)));
      });
    });

    group('Position', () {
      test('Position stores x and y coordinates', () {
        final pos = Position(5, 10);
        expect(pos.x, equals(5));
        expect(pos.y, equals(10));
      });

      test('Position translate moves in direction', () {
        final pos = Position(5, 5);
        final up = pos.translate(Direction.up);
        expect(up.x, equals(5));
        expect(up.y, equals(4));

        final down = pos.translate(Direction.down);
        expect(down.x, equals(5));
        expect(down.y, equals(6));

        final left = pos.translate(Direction.left);
        expect(left.x, equals(4));
        expect(left.y, equals(5));

        final right = pos.translate(Direction.right);
        expect(right.x, equals(6));
        expect(right.y, equals(5));
      });

      test('Position toKey returns string representation', () {
        final pos = Position(3, 7);
        expect(pos.toKey(), equals('3,7'));
      });

      test('Position equality works', () {
        final pos1 = Position(3, 7);
        final pos2 = Position(3, 7);
        final pos3 = Position(3, 8);

        expect(pos1, equals(pos2));
        expect(pos1, isNot(equals(pos3)));
      });

      test('Position hashCode is consistent', () {
        final pos1 = Position(3, 7);
        final pos2 = Position(3, 7);

        expect(pos1.hashCode, equals(pos2.hashCode));
      });

      test('Can use Position as map key (Set behavior)', () {
        final pos1 = Position(1, 1);
        final pos2 = Position(1, 1);
        final pos3 = Position(2, 2);

        final set = {pos1, pos2, pos3};
        expect(set.length, equals(2), reason: 'Duplicate positions should be treated as one');
      });
    });

    group('ArrowColor', () {
      test('ArrowColor from valid hex creates color', () {
        final color = ArrowColor.fromHex('#FF3366');
        expect(color.value, equals('#ff3366'));
      });

      test('ArrowColor accepts hex without hash', () {
        final color = ArrowColor.fromHex('00F5A0');
        expect(color.value, equals('#00f5a0'));
      });

      test('ArrowColor rejects invalid hex format', () {
        expect(
          () => ArrowColor.fromHex('GG0000'),
          throwsArgumentError,
          reason: 'Invalid hex characters should throw',
        );

        expect(
          () => ArrowColor.fromHex('#FF33'),
          throwsArgumentError,
          reason: 'Too short hex should throw',
        );

        expect(
          () => ArrowColor.fromHex('#FF330066'),
          throwsArgumentError,
          reason: 'Too long hex should throw',
        );
      });

      test('ArrowColor equality works', () {
        final color1 = ArrowColor.fromHex('#FF3366');
        final color2 = ArrowColor.fromHex('FF3366');
        final color3 = ArrowColor.fromHex('#FF3367');

        expect(color1, equals(color2));
        expect(color1, isNot(equals(color3)));
      });

      test('ArrowColor hashCode is consistent', () {
        final color1 = ArrowColor.fromHex('#FF3366');
        final color2 = ArrowColor.fromHex('#FF3366');

        expect(color1.hashCode, equals(color2.hashCode));
      });
    });

    group('TimeLimit', () {
      test('TimeLimit.none has 0 seconds', () {
        expect(TimeLimit.none.seconds, equals(0));
        expect(TimeLimit.none.hasLimit(), isFalse);
      });

      test('TimeLimit.of creates time limit', () {
        final limit = TimeLimit.of(120);
        expect(limit.seconds, equals(120));
        expect(limit.hasLimit(), isTrue);
        expect(limit.getValue(), equals(120));
      });

      test('TimeLimit rejects negative seconds', () {
        expect(
          () => TimeLimit.of(-1),
          throwsArgumentError,
        );
      });

      test('TimeLimit.of(0) is equivalent to TimeLimit.none', () {
        final limit = TimeLimit.of(0);
        expect(limit, equals(TimeLimit.none));
        expect(limit.hasLimit(), isFalse);
      });

      test('TimeLimit equality works', () {
        final limit1 = TimeLimit.of(60);
        final limit2 = TimeLimit.of(60);
        final limit3 = TimeLimit.of(120);

        expect(limit1, equals(limit2));
        expect(limit1, isNot(equals(limit3)));
      });

      test('TimeLimit hashCode is consistent', () {
        final limit1 = TimeLimit.of(60);
        final limit2 = TimeLimit.of(60);

        expect(limit1.hashCode, equals(limit2.hashCode));
      });
    });
  });
}
