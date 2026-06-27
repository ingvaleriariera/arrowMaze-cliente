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
| POST | `/progress/sync` | Bearer | `{userId, levels: [LevelProgressDTO]}` | `{levels: [LevelProgressDTO]}` |
| GET | `/leaderboard/:levelId` | No | — | `{entries: [{rank, username, score, achievedAt}]}` |

**NO existen:** `GET /levels/:id`, `GET /leaderboard` (global), `GET /scores/me`

**Score:** el más alto gana (BestScoreConflictResolver usa isGreaterThan).

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

**Condición de salida:** una flecha puede salir cuando su camino llega al
borde del tablero O a una celda void. Las celdas void actúan como
"salidas internas" — esto permite formas irregulares.

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

**Seed determinístico:** mismo levelId → mismas flechas siempre.

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

