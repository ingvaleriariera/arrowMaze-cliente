# Arrow Maze — Proyecto Semestral NRC 25783

## Descripción del juego

Arrow Maze es un clon del juego móvil de SayGames Ltd. Es un puzzle donde
el tablero está lleno de flechas de colores con forma de serpiente (multi-segmento).
El jugador toca flechas para activarlas.

**Regla principal:** una flecha solo puede salir del tablero si el camino
desde su cabeza hasta el borde (o celda void) está completamente libre de
otras flechas.

**Mecánica:**
- Las flechas son serpientes: ocupan varias celdas formando un cuerpo curvo
- Al activar una flecha, sale con animación de gusano (se desenrolla)
- Una flecha es activable si no hay nada en su trayectoria de salida
- Victoria: todas las flechas salen
- Derrota: se agotan los movimientos, el tiempo (HARD), o deadlock
- Los tableros pueden tener formas irregulares (cuadrado, corazón, cruz,
  diamante) definidas por un JSON del backend

**El juego tiene múltiples soluciones válidas** — el orden de activación
puede variar. No hay una única secuencia correcta.

---

## Stack tecnológico

- **Frontend:** Flutter + Riverpod
- **Backend:** NestJS + TypeORM + Supabase (PostgreSQL)
- **Auth:** JWT
- **Persistencia local:** sqflite
- **API docs:** Swagger/OpenAPI en http://localhost:3000/api/v1/docs
- **Commits:** Conventional Commits en inglés

---

## API Endpoints (Backend)

BASE URL: `http://localhost:3000/api/v1`

| Método | Endpoint | Auth | Body | Respuesta |
|--------|----------|------|------|-----------|
| POST | `/auth/register` | No | `{email, username, password}` | `{userId, username, token}` |
| POST | `/auth/login` | No | `{email, password}` — el campo `email` acepta correo O username (se resuelve por presencia de `@`) | `{userId, username, token}` |
| GET | `/levels` | No | — | `{levels: [LevelSummaryDTO]}` |
| POST | `/scores/submit` | Bearer | `{userId, levelId, score}` | `{accepted, qualifiedForLeaderboard}` |
| POST | `/progress/sync` | Bearer | `{userId, levels: [LevelProgressDTO], coins?}` | `{levels: [LevelProgressDTO], coins}` |
| GET | `/leaderboard/:levelId` | No | — | `{entries: [{rank, username, score, achievedAt}]}` |
| GET | `/leaderboard/global?limit=N` | No | — | `{entries: [{rank, username, totalScore}]}` |
| POST | `/custom-boards` | Bearer | `{name, difficulty, boardLayout}` (autor sale del JWT) | `{id, name, authorId, authorUsername, difficulty, boardLayout, createdAt}` |
| GET | `/custom-boards?limit=N` | No | — | `{boards: [CustomBoardHttpDTO]}` (más nuevos primero) |
| DELETE | `/custom-boards/:id` | Bearer | — | 204 (403 si no eres el autor, 404 si no existe) |

**NO existen:** `GET /levels/:id`, `GET /scores/me`

**Score:** el más alto gana (BestScoreConflictResolver usa isGreaterThan).

**Monedas:** persisten en el backend vía `progress/sync`. A diferencia de los
scores, usan last-write-wins (NO pasan por el conflict resolver de máximos,
porque un saldo gastable baja legítimamente). Enviar el body sin el campo
`coins` deja el saldo del servidor intacto — `undefined` nunca se trata como 0.
En el cliente, el sync toma max(local, servidor) como protección contra
pérdida de saldo (ver `game_progress_repository_impl.dart`).

**Economía de monedas (ganancia):** al completar un nivel por PRIMERA vez se
gana el score completo en monedas; al repetir un nivel ya completado se gana
el 25% del score (`GameProgress.replayCoinFactor`) — toda victoria paga algo
sin hacer trivial el farmeo. Se gastan en power-ups (in-game) y en vidas
(100 monedas por vida). Las cuentas nuevas arrancan con el saldo definido en
`game-economy.constants.ts` del backend.

**Leaderboard global:** suma el mejor score por nivel de cada jugador desde
`PlayerProgress` (NO desde `score_entries`, que es historial append-only y
contaría los replays dos veces).

---

## Niveles — origen y diseño

Los niveles se obtienen del backend vía `GET /api/v1/levels`. Cada nivel
incluye su forma de tablero (boardLayout) como JSON — un grid 2D donde
1 = celda válida y 0 = celda void.

**Decisión de diseño importante — ¿flechas en el JSON o generadas en el cliente?**

Hay dos enfoques posibles:

**Opción A — Flechas generadas proceduralmente en el cliente (implementación actual):**
- El backend solo define la forma del tablero
- El cliente genera las flechas con un algoritmo de construcción backward
- Ventaja: niveles infinitos, sin overhead en el backend
- Desventaja: dos jugadores en el mismo nivel pueden ver distribuciones
  diferentes de flechas, lo que hace el score no directamente comparable

**Opción B — Flechas definidas en el JSON del backend:**
- El backend almacena la posición exacta de cada flecha
- Todos los jugadores ven exactamente el mismo tablero
- Ventaja: experiencia consistente, scores 100% comparables en el leaderboard
- Desventaja: requiere diseñar los niveles manualmente o tener un generador
  en el backend

Para la entrega actual se usa la Opción A con seed determinístico
(mismo levelId → mismas flechas) para mitigar la inconsistencia.

---

## Motor del juego — BoardGraph

El núcleo del juego es un grafo de dependencias entre flechas:

- **Nodo** = una flecha
- **Arista** = "A está bloqueada por B" (B está en el camino de salida de A)
- **Activable** = blockedBy vacío → O(1)
- Al salir una flecha: se elimina su nodo y se desbloquean las flechas
  que dependían de ella

**Condición de salida (regla de void re-entry — IMPORTANTE):** una flecha
solo sale cuando su rayo llega más allá del borde exterior real del tablero
(la bounding box de la forma). Los huecos interiores NO son salidas: el
escaneo de bloqueos atraviesa el hueco, y si hay una flecha del otro lado
(void re-entry), la flecha está bloqueada por ella — se libera cuando esa
flecha dispara. Esta regla aplica idéntica en tres lugares que DEBEN estar
alineados: `BoardGraph.build` (blockedBy), el chequeo al tocar
(`hasVoidReentry` en PlayingState/GameNotifier), y la generación
(`BoardBuilder._isActivatable`). Historia: cuando la generación trataba el
hueco como salida y el juego no, los niveles con formas de anillo (nivel 15)
salían irresolubles.

**El grafo vive 100% en el cliente — el backend no valida jugadas.**

---

## Generador procedural de niveles

Las flechas se generan con algoritmo "backward construction":

1. Parte del tablero vacío
2. Por cada flecha: crece un camino serpiente en celdas disponibles
3. Verifica que la flecha sea activable EN ESE MOMENTO (camino libre)
4. Si es activable → la agrega y marca esas celdas como ocupadas
5. El orden inverso de construcción = solución garantizada

**Distribución de flechas (ver `_pickArrowLength` en BoardBuilder):**
- Cobertura: TODAS las celdas válidas terminan cubiertas (las que la
  generación principal no logra cubrir se rellenan con flechas de 1-2 celdas)
- 20% largas (8-15 segmentos, solo en tableros de lado ≥7)
- 33% medianas (4-7 segmentos)
- 33% cortas (2-3 segmentos)
- 14% de una celda

**Seed determinístico:** mismo levelId → mismas flechas siempre
(`seed = levelId.hashCode`, ver LoadLevelUseCase).

**Validación de resolubilidad:** cada intento de generación se valida
simulando una partida completa con la misma regla de activación del juego
real (incluyendo void re-entry). Las celdas que la generación principal no
cubre se rellenan con flechas de 1-2 celdas que respetan las mismas
validaciones (activable + sin cara-a-cara); si la simulación detecta flechas
atascadas, solo se re-tiran los rellenos (los ciclos siempre involucran
rellenos — las flechas del bucle principal son resolubles en orden inverso
por construcción).

---

## Economía y ritmo de juego

**Cronómetro (solo niveles HARD):** presupuesto de 2 segundos por flecha
generada, con piso de 60 segundos. Calculado en el cliente por
`PerArrowTimeLimitPolicy` (patrón Strategy detrás del puerto
`ITimeLimitPolicy`, inyectado en LoadLevelUseCase); si el backend enviara
`timeLimitSeconds` explícito, ese gana. Al agotarse: derrota `TIME_UP`.
HUD muestra `m:ss`, en rojo bajo 30s.

**Vidas:**
- Máximo 5; se pierde 1 por derrota (movimientos/deadlock/tiempo) y también
  por abandonar un nivel a mitad de partida (ambas salidas — gesto de atrás
  y botón del overlay de pausa — piden confirmación y avisan del costo).
- Regeneración: 1 vida cada 20 minutos, calculada lazy desde timestamps
  persistidos con recuperación acumulada (1 hora fuera = 3 vidas).
- Compra: 1 vida por 100 monedas (BuyLifeUseCase orquesta monedas + vidas).
- Con 0 vidas no se puede entrar a ningún nivel: todos los puntos de entrada
  muestran un diálogo con la cuenta regresiva en vivo y la opción de compra.
  El contador de corazones del Home es tocable y abre el mismo diálogo.
- Dominio: entidad inmutable `PlayerLives` (reloj inyectado por parámetro,
  testeable); almacenamiento en SharedPreferences por usuario —
  deliberadamente local al dispositivo, fuera del sync del backend y del
  esquema sqflite del progreso.
- La deducción por derrota se dispara UNA vez por sesión vía una bandera en
  GameScreen (`_lifeDeductedThisRun`) — no se puede deducir comparando el
  estado anterior del listener porque GameSession es mutable y previous/next
  comparten la misma instancia ya mutada.

---

## Tableros de la comunidad (editor de niveles)

Los jugadores diseñan y comparten sus propias FORMAS de tablero. Acceso:
ícono de lápiz en el Home → pantalla con pestañas Comunidad/Míos + botón
"Crear tablero".

**Editor (`board_editor_screen.dart`):** se elige un tamaño (8×8, 12×12 o
16×16), y se "dibuja" la forma en un lienzo de puntos: tocar o arrastrar
pinta/borra celdas (el arrastre pinta o borra según la primera celda tocada,
para que un trazo sea consistente). Se pone nombre y dificultad y se publica.

**Reglas de un tablero válido (validadas en el agregado `CustomBoard` del
backend, y espejadas en el editor):**
- Grid rectangular de 0s y 1s, entre 3 y 20 por lado
- Mínimo 10 celdas activas
- Nombre de 3 a 30 caracteres
- Solo el autor puede eliminarlo de la comunidad (verificado por JWT)

**Qué se guarda:** SOLO la forma (tabla `custom_boards` en PostgreSQL:
autor, nombre, dificultad, grid JSON, fecha). Las flechas NUNCA viajan —
cada cliente las genera con seed determinístico derivado del id del tablero,
así todos los que adopten el mismo tablero ven las mismas flechas.

**Adopción y juego:** "Agregar" guarda una copia local del tablero
(SharedPreferences, `MyBoardsRepositoryImpl`) — jugable incluso offline.
Los adoptados aparecen al final del grid de selección de niveles (borde
cian, ícono de lápiz, nombre del tablero) y se juegan por el pipeline normal
gracias a `CustomAwareLevelRepository` (patrón Decorator sobre
`ILevelRepository`): los ids con prefijo `custom-` se resuelven de la lista
local y se adaptan a un `Level` normal — el pipeline de juego no distingue
tableros de jugadores de niveles del seeder.

**Juego libre:** los tableros custom no tocan progresión, desbloqueos,
sync ni leaderboards (guard en `GameNotifier._handleSessionOverIfNeeded` y
en el preload de "siguientes niveles"). Vidas y victoria/derrota funcionan
normal. Los HARD custom heredan el cronómetro automáticamente (misma
política por dificultad). El botón Jugar del Home ignora los custom al
calcular el "nivel actual".

**Vistas previas baratas:** `BoardShapePreview` pinta el grid como puntitos
(sin flechas, sin generación) — las listas de comunidad escalan sin costo.

---

## Modo 3D del tablero

Toggle "Tablero 3D" en Configuración (`board3DEnabled` en SettingsState).
Activo, `Board3DViewport` proyecta el tablero en perspectiva: arrastre
horizontal lo gira (eje Y), vertical lo inclina (eje X), mantener presionado
lo recentra; pinch-zoom sigue funcionando. Ángulos acotados a ~72°.

**Decisión de rendimiento (crítica):** el tablero SIEMPRE se rasteriza en
plano a una imagen GPU (`SnapshotWidget`) y la perspectiva se aplica a esa
imagen; la imagen se refresca cuando cambia el estado del juego (moves,
flashes, ticks). Rasterizar los blurs del painter A TRAVÉS de la matriz de
perspectiva (el enfoque ingenuo) asigna buffers offscreen gigantes en
tableros grandes y congela el hilo de raster — el nivel 15 colgaba la app
entera. No revertir este diseño.

**Es 100% capa de presentación:** dominio, casos de uso y backend no saben
que existe. El renderer plano sigue siendo el default; el toggle elige la
estrategia en runtime.

---

## Requisitos Funcionales

| # | Requisito | Estado |
|---|-----------|--------|
| RF01 | Motor de juego: activar flechas, detectar bloqueos | ✅ |
| RF02 | Tableros de formas irregulares desde JSON del backend | ✅ |
| RF03 | Generación procedural de flechas (cliente) | ✅ |
| RF04 | Límite de movimientos por nivel | ✅ |
| RF05 | Detección de deadlock → derrota | ✅ |
| RF06 | Cronómetro en niveles HARD | ✅ |
| RF07 | Pausa del juego | ✅ |
| RF08 | Power-ups: Pista, Martillo, Imán | ✅ |
| RF09 | Sistema de monedas para power-ups | ✅ |
| RF10 | Registro e inicio de sesión con JWT | ✅ |
| RF11 | Persistencia local del progreso (sqflite) | ✅ |
| RF12 | Sincronización del progreso con backend | ✅ |
| RF13 | Tabla de clasificación global por nivel | ✅ |
| RF14 | Pantalla de selección de niveles con progreso | ✅ |
| RF15 | 15 niveles con dificultad progresiva (easy/medium/hard) | ✅ |
| RF16 | Animación de salida de flechas (efecto gusano) | ⏳ |
| RF17 | Efectos de sonido y música, opción de silenciar | ✅ |
| RF18 | Soporte español e inglés (i18n) | ✅ |
| RF19 | Clasificación global (suma de mejores scores) con podio top 3 | ✅ |
| RF20 | Pantalla de inicio, perfil con avatar local y navegación con atrás | ✅ |
| RF21 | Sistema de vidas: 5 máx, regeneración 20 min, compra con monedas | ✅ |
| RF22 | Login con usuario o correo; prellenado con credenciales de Face ID | ✅ |
| RF23 | Editor de tableros + tableros de la comunidad (crear/adoptar/eliminar) | ✅ |
| RF24 | Modo 3D del tablero (toggle, rotación con perspectiva) | ✅ |

---

## Requisitos No Funcionales

| # | Requisito |
|---|-----------|
| RNF01 | Clean Architecture 4 capas |
| RNF02 | Principios SOLID |
| RNF03 | Patrones GoF (Creacional, Estructural, Comportamiento) |
| RNF04 | AOP — mínimo 1 aspecto |
| RNF05 | Autenticación JWT |
| RNF06 | Documentación Swagger/OpenAPI |
| RNF07 | Pruebas unitarias |
| RNF08 | Conventional Commits en inglés |
| RNF09 | AI_USAGE.md documentando uso de IA |

---

## Módulos del sistema

**Backend (NestJS — un módulo por contexto, registrados en `app.module.ts`):**

| Módulo | Responsabilidad | Piezas clave |
|--------|-----------------|--------------|
| Auth | Registro, login (email o username), JWT | `LoginUserUseCase`, `JwtAuthGuard`, `JwtTokenProviderImpl`; exporta `USER_REPOSITORY` |
| Level | Niveles estándar seeded | `LevelDefinition` (agregado), `DatabaseSeeder` (upsert al arrancar) |
| Progress | Progreso sincronizado + monedas | `PlayerProgress` (agregado), `SyncProgressUseCase`, `BestScoreConflictResolver` |
| Score | Historial de scores (append-only) | `SubmitScoreUseCase`, tabla `score_entries` |
| Leaderboard | Clasificación por nivel y global | `GetLeaderboardUseCase`, `GetGlobalLeaderboardUseCase` |
| CustomBoard | Tableros de jugadores | `CustomBoard` (agregado con validación de grid), create/list/delete use cases |

Transversales (AOP): `LoggingInterceptor` (APP_INTERCEPTOR) y
`HttpExceptionFilter` (APP_FILTER).

**Cliente (Flutter — 4 capas, dependencias solo hacia adentro):**

| Capa | Contenido |
|------|-----------|
| `domain/` | Entidades (Board, GameSession, GameProgress, PlayerLives), value objects (Direction, Position, TimeLimit…), builders (BoardBuilder), grafo (BoardGraph), estados del juego (State pattern), power-ups, puertos del dominio |
| `application/` | Casos de uso (auth, game, progress, lives, boards, leaderboard, score), DTOs, puertos de aplicación |
| `adapters/` | Repositorios (API/sqflite/SharedPreferences), mappers, notifiers Riverpod + estados, ApiClient |
| `infrastructure/` | Pantallas, widgets, painters, router (GoRouter), i18n, interceptores HTTP, servicios de plataforma (biometría, audio) |

---

## Principios y patrones que cumple el proyecto

**Arquitectura por capas (RNF01):** ambas apps tienen 4 capas con la regla
de dependencia hacia adentro: el dominio no importa nada de las otras capas;
la aplicación solo conoce dominio; adapters implementa los puertos; la
infraestructura está en el borde. El dominio del juego (grafo, generador,
reglas) no sabe que existen Flutter, HTTP ni SQL.

**Inversión de dependencias (la D de SOLID):** los casos de uso dependen de
ABSTRACCIONES (puertos) y las implementaciones se inyectan desde afuera:
- Backend: interfaces + tokens de NestJS (`IConflictResolver`/`CONFLICT_RESOLVER`,
  `ICustomBoardRepository`/`CUSTOM_BOARD_REPOSITORY`, `IUserRepository`…),
  cableados en los módulos con `{provide, useClass}`.
- Cliente: puertos abstractos (`ILevelRepository`, `IGameProgressRepository`,
  `ILivesRepository`, `ITimeLimitPolicy`, `ICustomBoardRepository`…) cableados
  en `providers.dart` (Riverpod actúa como contenedor de DI); los providers se
  tipan con la interfaz, no con la clase concreta.

**Resto de SOLID:**
- **S**: un caso de uso = una operación (LoseLifeUseCase, SubmitScoreUseCase…);
  notifiers como único dueño de su estado (LivesNotifier posee toda mutación
  de vidas).
- **O**: nuevas reglas sin tocar consumidores — otra política de tiempo es una
  clase nueva detrás de `ITimeLimitPolicy`; el modo 3D se agregó sin tocar el
  pipeline de juego; los tableros custom entraron por un decorator sin
  modificar LoadLevelUseCase.
- **L**: cualquier implementación de un puerto es sustituible (los tests
  sustituyen repos reales por fakes en memoria sin tocar los casos de uso).
- **I**: puertos chicos y específicos (ILivesRepository ≠ IGameProgressRepository;
  IScoreRepository con un solo método).

**Patrones GoF en uso:**

| Patrón | Dónde |
|--------|-------|
| Strategy | `BestScoreConflictResolver` (resolución de conflictos de score), `PerArrowTimeLimitPolicy` (cronómetro), power-ups (`PowerUp` con Hint/Grid/Hammer/Magnet), renderer 2D/plano vs `Board3DViewport` elegido en runtime |
| State | `IGameState` con PlayingState/PausedState/VictoryState/DefeatState — GameSession delega el manejo de jugadas al estado actual |
| Decorator | `CustomAwareLevelRepository` envuelve el repo de niveles y agrega resolución de tableros custom sin que el pipeline lo note |
| Builder | `BoardBuilder` (construcción del tablero con generación), `LevelConfigBuilder` (backend) |
| Repository | Todos los accesos a datos, detrás de puertos en ambas apps |
| Factory Method | Los value objects (`Score.create`, `Difficulty.create`, `TimeLimit.of`…) validan en la creación — no existen instancias inválidas |
| Observer | Riverpod StateNotifier: las pantallas observan estado y reaccionan (`ref.watch`/`ref.listen`) |
| Singleton | `GameProgressDatabase` (una conexión sqflite por proceso) |

**DDD táctico (backend):** agregados (`PlayerProgress`, `CustomBoard`,
`LevelDefinition`, `User`) con constructores privados + `create`/`reconstitute`,
value objects inmutables con validación propia, y las reglas de negocio DENTRO
del agregado (p. ej. la validación del grid vive en `CustomBoard.create`, no
en el controller).

**AOP (RNF04):** `LoggingInterceptor` y `HttpExceptionFilter` globales en el
backend — logging y manejo de errores como aspectos transversales, fuera de
la lógica de negocio.

**Testabilidad por diseño:** el reloj se inyecta por parámetro
(`PlayerLives.regenerated(now)`), los casos de uso reciben puertos mockeables,
y la resolubilidad de la generación se prueba con la MISMA regla de activación
del juego real.

---

## Diagramas del proyecto

Los diagramas PlantUML están en la carpeta `/docs/` del repo.
Cubren las 4 capas del cliente Flutter y las 4 capas del backend NestJS.

// Nota: algunos nombres de archivos pueden haber cambiado desde que
// se crearon los diagramas originales. Verifica los nombres reales
// en la carpeta /docs/ antes de referenciarlos.

---

## Referencia visual del juego

`docs/arrow_maze_v5.html` — prototipo HTML jugable con la mecánica
completa implementada en JavaScript. Úsalo como referencia visual
para el rendering y la animación, NO copies el código JavaScript.

---

## Convenciones del proyecto

- Archivos Dart: `snake_case.dart`
- Clases: `PascalCase`
- Variables/métodos: `camelCase`
- Commits: `tipo(scope): descripción en inglés`
  - tipos: feat, fix, chore, docs, test, refactor
- El frontend NO accede directamente a Supabase — todo pasa por el backend
- CORS habilitado en el backend para desarrollo local

