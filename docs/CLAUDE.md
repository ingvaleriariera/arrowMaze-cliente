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
| POST | `/auth/login` | No | `{email, password}` | `{userId, username, token}` |
| GET | `/levels` | No | — | `{levels: [LevelSummaryDTO]}` |
| POST | `/scores/submit` | Bearer | `{userId, levelId, score}` | `{accepted, qualifiedForLeaderboard}` |
| POST | `/progress/sync` | Bearer | `{userId, levels: [LevelProgressDTO], coins?}` | `{levels: [LevelProgressDTO], coins}` |
| GET | `/leaderboard/:levelId` | No | — | `{entries: [{rank, username, score, achievedAt}]}` |
| GET | `/leaderboard/global?limit=N` | No | — | `{entries: [{rank, username, totalScore}]}` |

**NO existen:** `GET /levels/:id`, `GET /scores/me`

**Score:** el más alto gana (BestScoreConflictResolver usa isGreaterThan).

**Monedas:** persisten en el backend vía `progress/sync`. A diferencia de los
scores, usan last-write-wins (NO pasan por el conflict resolver de máximos,
porque un saldo gastable baja legítimamente). Enviar el body sin el campo
`coins` deja el saldo del servidor intacto — `undefined` nunca se trata como 0.
Temporal para testing: el cliente fuerza el saldo local a 9999 en cada sync
(ver `game_progress_repository_impl.dart`) hasta que exista economía real de
ganancia de monedas.

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

**Distribución de flechas:**
- Cobertura: 50-60% de celdas válidas
- 20% flechas largas (4-5 segmentos)
- 20% flechas medianas (3 segmentos)
- 10% flechas cortas (1-2 segmentos)
- 50% normales (2-3 segmentos)

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

