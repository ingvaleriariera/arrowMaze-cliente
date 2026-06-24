# Domain Layer (Capa 1) - Arrow Maze Flutter Client

## Overview

The Domain Layer is the pure Dart business logic core of the Arrow Maze game. It contains no Flutter dependencies and can be used independently for game logic processing, testing, and validation.

## Architecture

### Value Objects (`lib/domain/value_objects/`)

Immutable objects representing core game values:

- **`Position`** — 2D coordinate (x, y) with translation support
- **`Direction`** — Cardinal directions (UP, DOWN, LEFT, RIGHT) as factory-constructed singletons
- **`ArrowColor`** — Validated hex color codes
- **`TimeLimit`** — Non-negative time duration with optional limits
- **`MoveResult`** — Result of executing a move (success/failure with segments list)

### Entities (`lib/domain/entities/`)

Core game objects:

- **`ArrowSegment`** — Single cell of an arrow with position and direction to next segment
- **`Arrow`** — Multi-segment arrow with ID, segments, and color
- **`BoardShape`** — Set of valid cells parsed from JSON, supports boundary checks
- **`Board`** — Game board state: shapes, arrows, grid mapping, and dependency graph
- **`Level`** — Level configuration with layout, move limits, and time constraints
- **`GameProgress`** — Player progress tracking with completions, best scores, and coins
- **`GameSession`** — Active game session with state management and move execution

### Dependency Graph (`lib/domain/graph/`)

Implements the blocking/activation mechanism:

- **`ArrowNode`** — Represents an arrow in the dependency graph with a set of blocker IDs
- **`BoardGraph`** — Manages all nodes and the blocking relationships
  - Builds graph by scanning exit paths for intersections
  - Recalculates when arrows are removed
  - Identifies activatable arrows (those with zero blockers)

### Game States (`lib/domain/states/`)

State machine implementation following the State pattern:

- **`IGameState`** — Abstract base for all states
- **`PlayingState`** — Processes moves, checks for victory/deadlock
- **`PausedState`** — Prevents all moves
- **`VictoryState`** — Game won (board empty)
- **`DefeatState`** — Game lost (reasons: OUT_OF_MOVES, DEADLOCK, TIME_UP)

### Power-ups (`lib/domain/powerups/`)

Template Method pattern for power-up mechanics:

- **`PowerUp`** — Abstract base with `canApply()` hook and `apply()` template
- **`HintPowerUp`** — Shows activatable arrow (no board modification)
- **`HammerPowerUp`** — Force-removes a target arrow
- **`MagnetPowerUp`** — Removes all activatable arrows pointing in a direction
- **`PowerUpResult`** — Result of power-up application

### Builders (`lib/domain/builders/`)

- **`BoardBuilder`** — Fluent builder pattern for constructing Board instances with graph initialization

### Validators (`lib/domain/validators/`)

- **`LevelValidator`** — Validates level data and detects unsolvable boards using Kahn's algorithm

### Ports/Interfaces (`lib/domain/ports/`)

Abstract interfaces for external dependencies:

- **`ILevelRepository`** — Level data access (to be implemented by data layer)
- **`IGameProgressRepository`** — Progress persistence (to be implemented by data layer)

## Key Game Logic

### Blocking Mechanism

1. For each arrow, scan from the cell **after the head** in the arrow's direction
2. Continue scanning until reaching the board edge or void cell (exit)
3. Any arrow encountered in this path blocks the current arrow
4. Arrow is activatable only if `blockedBy` set is empty

### Move Execution

1. Check if arrow is activatable
2. Remove arrow from board and grid
3. Recalculate dependency graph
4. Check victory (board empty) or deadlock (no activatable arrows)
5. Check defeat by move count or time

### Victory/Defeat Conditions

- **Victory**: Board is empty (`arrows.isEmpty`)
- **Defeat (OUT_OF_MOVES)**: Moves exceed `maxMoves`
- **Defeat (DEADLOCK)**: No activatable arrows remain but board isn't empty
- **Defeat (TIME_UP)**: Time counter reaches 0

## Testing

All core scenarios verified:

✅ Scenario 1: Blocking chain detection (C blocks B, B blocks A)
✅ Scenario 2: Unblocking after removal
✅ Scenario 3: Complete game flow to victory
✅ Scenario 4: Defeat by exceeding move limit
✅ Scenario 5: Hammer power-up on blocked arrow
✅ Scenario 6: Solvability detection (Kahn's algorithm)

Run tests:
```bash
flutter test test/domain_layer_test.dart
```

## Design Patterns Used

- **Value Objects** — Immutable, self-validating domain types
- **Factory Methods** — Direction and TimeLimit construction
- **Builder Pattern** — BoardBuilder for complex object construction
- **State Pattern** — IGameState and implementations
- **Template Method** — PowerUp.use() with canApply() hook
- **Dependency Injection** — Interfaces for repositories (ILevelRepository, IGameProgressRepository)

## Integration Points

The Domain Layer exposes these public APIs for the Presentation/UI layer:

```dart
// Create a game session
final board = BoardBuilder.create()
    .setShape(shape)
    .addArrow(arrow1)
    .addArrow(arrow2)
    .build();

final session = GameSession(
    board: board,
    levelId: 'level_001',
    maxMoves: 15,
    timeRemaining: 180,
);

// Execute moves
final result = session.executeMove(arrowId);
if (result.success) {
    // Update UI with score, moves, remaining arrows
}

// Pause/Resume
session.pause();
session.resume();

// Apply power-ups
final hint = HintPowerUp();
final result = hint.use(board);

// Check game state
if (session.isOver()) { /* show overlay */ }
if (session.state is VictoryState) { /* show win screen */ }
```

## Next Steps (Capa 2: Presentation)

The Presentation Layer will:
- Create widgets for board visualization
- Handle user input and translate to game moves
- Manage UI state and animations
- Coordinate with Data Layer for persistence
- Implement power-up UI interactions
