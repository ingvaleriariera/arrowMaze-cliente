# Arrow Maze — Flutter Client

Clon del juego Arrow Maze (SayGames). Puzzle donde el jugador activa flechas
para que salgan del tablero. Una flecha solo sale si su camino hasta el borde
(o celda void) está libre de otras flechas.

**Stack:** Flutter + Riverpod | Dart  
**Backend:** NestJS + Supabase (PostgreSQL) | Base URL: `http://localhost:3000/api/v1`  
**Repo backend:** `ingvaleriariera/arrowMaze-backend`  
**Rama activa:** `develop`

---

## Arquitectura — Clean Architecture 4 capas

La regla de dependencia es ESTRICTA: las dependencias solo apuntan hacia adentro.
Capa 4 → Capa 3 → Capa 2 → Capa 1. NUNCA al revés.

```
lib/
  domain/        ← Capa 1: lógica pura, cero dependencias externas
  application/   ← Capa 2: casos de uso, orquesta el dominio
  adapters/      ← Capa 3: Riverpod notifiers, repos concretos, ApiClient
  ui/            ← Capa 4: widgets Flutter, screens, interceptores Dio
```

**NO usar DDD en el frontend.** Sin `@AggregateRoot`, sin `@Entity`, sin
`@ValueObject`. Eso es solo del backend. Aquí son clases Dart normales.

---

## Capa 1 — Domain (`lib/domain/`)

**Regla:** Cero imports de Flutter, Dio, sqflite o cualquier paquete externo.
Solo Dart puro. Si un archivo de dominio importa algo de `package:flutter/`
o `package:dio/`, está mal.

### Estructura
```
domain/
  entities/           # Board, GameSession, Level, Arrow, GameProgress, MoveResult
  engine/             # BoardGraph, ArrowNode
  state/              # IGameState, PlayingState, PausedState, VictoryState, DefeatState
  power_ups/          # PowerUp (abstract), HintPowerUp, HammerPowerUp, MagnetPowerUp
  value_objects/      # Position, Direction, ArrowSegment, BoardShape, ArrowColor, TimeLimit
  builders/           # BoardBuilder
  validators/         # LevelValidator
  ports/              # ILevelRepository, IGameProgressRepository
```

### Clases clave

**Board** — el tablero. Tiene `shape: BoardShape`, `arrows: Map<String, Arrow>`,
`grid: Map<String, String>` (key="x,y" → arrowId), `graph: BoardGraph`.
Métodos: `removeArrow()`, `forceRemoveArrow()` (martillo), `getHint()`, `isActivatable()`.

**GameSession** — partida activa. Tiene `board`, `levelId`, `score: int`,
`moves: int`, `maxMoves: int`, `timeRemaining: int?`, `state: IGameState`.
Métodos: `executeMove()`, `applyPowerUp()`, `pause()`, `resume()`, `tick()`.
DELEGA en `state.handle()` — sin if/else en GameSession.

**BoardGraph** — núcleo del motor. Grafo de dependencias entre flechas.
Nodo = flecha. Arista = "A bloqueada por B" (B en el camino de A).
Activable = `blockedBy` vacío → O(1).
Métodos: `build()`, `removeArrow()`, `getActivatable()`, `isActivatable()`.

**BoardShape** — forma del tablero. Se crea desde el JSON del backend:
```dart
// JSON del backend:
// { "grid": [[0,1,0],[1,0,1],[0,1,0]], "rows": 3, "cols": 3 }
// 1 = celda válida, 0 = void
BoardShape.fromJson(String json)
```
Internamente usa `Set<String>` donde cada elemento es `"x,y"`. Búsqueda O(1).

**Direction** — constructor privado + factories estáticos:
`Direction.up()`, `Direction.down()`, `Direction.left()`, `Direction.right()`

**IGameState** (interfaz) — contrato del patrón State:
```dart
abstract class IGameState {
  MoveResult handle(String arrowId, Board board);
  bool isPlaying();
  bool isOver();
  String getLabel();
}
```
Implementado por: `PlayingState`, `PausedState`, `VictoryState`, `DefeatState`.

**PowerUp** (abstract — Template Method):
```dart
abstract class PowerUp {
  PowerUpResult use(Board board) {           // método plantilla (no se sobreescribe)
    if (!canApply(board)) return PowerUpResult.failure('Cannot apply');
    apply(board);
    return PowerUpResult.success(null);
  }
  bool canApply(Board board) => true;       // hook opcional
  void apply(Board board);                  // hook abstracto — OBLIGATORIO
  int getCost();
  String getType();
}
```

**Level** — nivel del backend. Tiene: `id`, `difficulty`, `moveLimit`, 
`boardLayout: String` (JSON), `version: int`.
**NO tiene flechas** — las flechas se generan proceduralmente en el cliente.

**GameProgress** — progreso local del jugador:
`userId`, `completedLevels: Map<String, LevelProgress>`, `coins: int`.
Donde `LevelProgress = { bestScore: int, completedAt: String }`.

### Generador procedural de niveles
Las flechas NO vienen del backend. Se generan en el cliente con garantía
de solvabilidad (construcción backward). Ver `lib/domain/engine/level_generator.dart`.
Algoritmo: cada flecha añadida debe ser activable → el orden inverso es válido.

---

## Capa 2 — Application (`lib/application/`)

**Regla:** Solo imports de Capa 1. Sin Flutter, sin Dio, sin sqflite.
Los casos de uso son stateless — no guardan `GameSession` internamente.

### Casos de uso
```
use_cases/
  game/
    load_level_use_case.dart          # GET /levels → BoardShape → genera flechas → GameSession
    activate_arrow_use_case.dart      # session.executeMove(arrowId) → MoveResult
    pause_level_use_case.dart         # session.pause()
    resume_level_use_case.dart        # session.resume()
    restart_level_use_case.dart       # delega en LoadLevelUseCase
    get_level_summaries_use_case.dart # combina niveles + progreso local → pantalla selección
  power_ups/
    use_power_up_use_case.dart        # verifica coins → applyPowerUp → guarda progreso
  auth/
    login_use_case.dart               # POST /api/v1/auth/login
    register_use_case.dart            # POST /api/v1/auth/register
    logout_use_case.dart              # limpia token local
  progress/
    save_progress_use_case.dart       # guarda GameProgress local (sqflite)
    get_local_progress_use_case.dart  # carga GameProgress local
    sync_progress_use_case.dart       # POST /api/v1/progress/sync
    submit_score_use_case.dart        # POST /api/v1/scores/submit
    get_leaderboard_use_case.dart     # GET /api/v1/leaderboard/:levelId
```

### Ports de Capa 2 (no son de dominio del juego)
```
ports/
  i_auth_repository.dart             # login, register, logout, getToken, isAuthenticated
  i_leaderboard_repository.dart      # getTopScores(levelId, limit)
  i_audio_service.dart               # playEffect, playMusic, mute, unmute
```

### DTOs
```
dtos/
  login_input_dto.dart               # { email, password }
  register_input_dto.dart            # { email, username, password }
  auth_result_dto.dart               # { token, userId, username }
  leaderboard_entry_dto.dart         # { rank, username, score, achievedAt }
  level_summary_dto.dart             # { levelId, difficulty, completed, bestScore, isTimed }
  submit_score_result_dto.dart       # { accepted, qualifiedForLeaderboard }
```

---

## Capa 3 — Adapters (`lib/adapters/`)

**Regla:** Implementa los ports de C1 y C2. Puede importar Dio, sqflite,
flutter_secure_storage. NO puede importar widgets de Flutter (eso es C4).

### Notifiers (Riverpod StateNotifier — son los Presenters)
```
notifiers/
  game_notifier.dart           # guarda GameSession, llama UCs de juego y power-ups
  auth_notifier.dart           # estado de auth, llama UCs de auth
  level_select_notifier.dart   # lista de niveles para pantalla de selección
  leaderboard_notifier.dart    # datos del leaderboard
  settings_notifier.dart       # mute/unmute audio
```

**GameNotifier** es el más complejo. Maneja:
- `GameSession? session` y `GameProgress? progress` como estado
- `Timer? _timer` para el cronómetro (niveles HARD)
- `startTimer()` → `Timer.periodic(1s, (_) => session.tick())`
- `useHint/Hammer/Magnet()` → instancia el PowerUp concreto → `UsePowerUpUseCase`

### Repositories (Adapters GoF)
```
repositories/
  level_repository_impl.dart          # implementa ILevelRepository (C1) → HTTP
  game_progress_repository_impl.dart  # implementa IGameProgressRepository (C1) → sqflite + HTTP
  auth_repository_impl.dart           # implementa IAuthRepository (C2) → HTTP + secure storage
  leaderboard_repository_impl.dart    # implementa ILeaderboardRepository (C2) → HTTP
```

### ApiClient (Facade GoF)
```
api/
  api_client.dart   # wrapper de Dio, agrega JWT automáticamente
                    # BASE_URL = 'http://localhost:3000/api/v1'
```

### Mappers
```
mappers/
  level_mapper.dart      # JSON (backend) → Level (domain)
  progress_mapper.dart   # Map (sqflite) ↔ GameProgress (domain)
```

---

## Capa 4 — UI (`lib/ui/`)

**Regla:** Solo Screens y Widgets. Observan Notifiers de C3. No llaman
Use Cases directamente — todo va por el Notifier.

### Screens
```
screens/
  splash_screen.dart         # check auth → navega a login o level_select
  login_screen.dart          # observa AuthNotifier
  register_screen.dart       # observa AuthNotifier
  level_select_screen.dart   # observa LevelSelectNotifier
  game_screen.dart           # observa GameNotifier — la más compleja
  victory_screen.dart        # observa GameNotifier
  defeat_screen.dart         # observa GameNotifier
  leaderboard_screen.dart    # observa LeaderboardNotifier
  settings_screen.dart       # observa SettingsNotifier
```

**GameScreen** renderiza el tablero con `CustomPainter` (no Stack de widgets).
El painter lee `GameNotifier.session.board` y dibuja las flechas.
Animación de salida de flechas implementada en el painter.

### Interceptores Dio (AOP)
```
interceptors/
  auth_interceptor.dart      # inyecta JWT en cada request, maneja 401
  logging_interceptor.dart   # logs en debug mode
  error_interceptor.dart     # convierte DioError en excepciones tipadas
```

### App setup
```
app/
  app_router.dart            # go_router routes
  my_app.dart                # MaterialApp + ProviderScope
```

---

## API Endpoints (Backend)

BASE URL: `http://localhost:3000/api/v1`

| Método | Endpoint | Auth | Input | Output |
|--------|----------|------|-------|--------|
| POST | `/auth/register` | No | `{email, username, password}` | `{userId, username, token}` |
| POST | `/auth/login` | No | `{email, password}` | `{userId, username, token}` |
| GET | `/levels` | No | — | `{levels: [LevelSummaryDTO]}` |
| POST | `/scores/submit` | Bearer | `{userId, levelId, score}` | `{accepted, qualifiedForLeaderboard}` |
| POST | `/progress/sync` | Bearer | `{userId, levels: [LevelProgressDTO]}` | `{levels: [LevelProgressDTO]}` |
| GET | `/leaderboard/:levelId` | No | — | `{entries: [{rank, username, score, achievedAt}]}` |

**LevelSummaryDTO (backend):**
```json
{ "id": "level-001", "difficulty": "easy", "moveLimit": 15,
  "boardLayout": "{\"grid\":[[0,1],[1,0]],\"rows\":2,\"cols\":2}", "version": 1 }
```

**LevelProgressDTO (sync):**
```json
{ "levelId": "level-001", "bestScore": 850, "completedAt": "2026-06-20T12:00:00Z" }
```

**Score:** mayor es mejor. `POST /scores/submit` envía el score de `GameSession.score`.

**NO existen:** `GET /levels/:id`, `GET /leaderboard` (global), `GET /scores/me`

---

## Patrones GoF implementados

| Categoría | Patrón | Clase |
|-----------|--------|-------|
| Creacional | Factory Method | `Direction.up/down/left/right()`, `TimeLimit.none/of()`, `ArrowColor.fromHex()` |
| Creacional | Builder | `BoardBuilder` (lib/domain/builders/) |
| Comportamiento | State | `IGameState` + `PlayingState`, `PausedState`, `VictoryState`, `DefeatState` |
| Comportamiento | Template Method | `PowerUp` + `HintPowerUp`, `HammerPowerUp`, `MagnetPowerUp` |
| Estructural | Adapter | Los 4 `*RepositoryImpl` en adapters/repositories/ |
| Estructural | Facade | `ApiClient` en adapters/api/ |

---

## Convenciones de código

**Archivos:** `snake_case.dart` siempre.  
**Clases:** `PascalCase`.  
**Variables/métodos:** `camelCase`.  
**Constantes:** `kConstantName` o `UPPER_SNAKE_CASE` para valores globales.  
**Tests:** `widget_test.dart` → `test/` con misma estructura que `lib/`.

**Imports — orden:**
```dart
import 'dart:async';                    // 1. Dart core
import 'package:flutter/material.dart'; // 2. Flutter
import 'package:riverpod/riverpod.dart';// 3. Paquetes externos
import '../domain/entities/board.dart'; // 4. Imports locales (relativos)
```

**No usar `dynamic`** salvo para parsear JSON externo (en mappers).  
**No usar `late` sin inicializar en el constructor** salvo casos justificados.  
**Siempre tipar** los retornos de métodos de Use Cases y Repositories.

---

## Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  dio: ^5.4.3
  sqflite: ^2.3.3
  flutter_secure_storage: ^9.2.2
  go_router: ^14.2.7
  just_audio: ^0.9.40
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

---

## Notas importantes

- Las flechas NO vienen del backend. Se generan proceduralmente en el cliente.
- `BoardShape.fromJson()` parsea el `boardLayout` JSON del backend (grid 2D de 0/1).
- El score más alto gana (BestScoreConflictResolver del backend usa `isGreaterThan`).
- CORS no está configurado en el backend — en Flutter mobile no importa.
- `GET /levels` devuelve TODOS los niveles — no hay endpoint por ID.
- El token JWT se guarda con `flutter_secure_storage`, no en SharedPreferences.
- El cronómetro (HARD) lo maneja `GameNotifier._timer` con `Timer.periodic`.
