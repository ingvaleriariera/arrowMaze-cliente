# Arrow Maze — Cliente (Flutter)

Cliente Flutter del puzzle **Arrow Maze**: tableros con figuras (cuadrado, diamante, corazón, corona, reloj de arena, etc.) llenos de flechas-serpiente que hay que sacar del tablero en el orden correcto, sin que se bloqueen entre sí.

Este repo es solo el **frontend**. Necesita el backend (`arrowMaze-backend`) corriendo para login, niveles y leaderboard — ver [Backend](#backend).

## Arquitectura

El proyecto sigue una arquitectura en 4 capas con inversión de dependencias (los diagramas completos están en `docs/*.puml`):

```
lib/
├── domain/          # Entidades, value objects, reglas del juego puras (sin Flutter)
│   ├── entities/        Board, BoardShape, Arrow, GameSession, Level...
│   ├── value_objects/   Position, Direction, ArrowColor...
│   ├── states/          IGameState: PlayingState, PausedState, VictoryState, DefeatState
│   ├── graph/           BoardGraph (quién bloquea a quién)
│   ├── builders/        BoardBuilder (generador procedural de flechas)
│   ├── powerups/        Hint, Hammer, Magnet (lógica de dominio)
│   └── ports/           Interfaces que infraestructura debe implementar
├── application/     # Casos de uso (orquestan domain + ports) y DTOs
│   ├── usecases/        LoadLevel, ActivateArrow, Login, GetLeaderboard...
│   └── ports/           IAudioService, etc.
├── adapters/        # Riverpod: notifiers + state inmutable + repos/mappers/API
│   ├── notifiers/       GameNotifier, AuthNotifier, SettingsNotifier...
│   ├── state/           GameState, AuthState...
│   ├── repositories/    Implementaciones de los ports del dominio
│   └── api/              Cliente HTTP (Dio)
└── infrastructure/  # Flutter puro: pantallas, widgets, router, i18n
    ├── screens/         GameScreen, LevelSelectScreen, LoginScreen...
    ├── widgets/         BoardPainter (CustomPainter del tablero)
    └── config/          AppRouter (go_router), AppLocalizations (en/es)
```

La regla de dependencia es de afuera hacia adentro: `infrastructure → adapters → application → domain`. El dominio no importa nada de Flutter.

### Generación de niveles

Los tableros (la *forma* válida del grid) vienen del backend. Las **flechas se generan en el cliente** (`BoardBuilder`), con una semilla determinística por nivel (`level.id.hashCode`) para que todos los jugadores vean el mismo layout y los puntajes del leaderboard sean comparables. El generador:

- Cubre el 100% de las celdas válidas de la figura (nunca deja huecos).
- Mezcla longitudes de flecha (largas/medianas/cortas/de 1 celda) con más variedad en tableros grandes.
- Descarta cualquier flecha cuya salida la bloquee a sí misma (sería imposible de sacar).
- Reintenta hasta encontrar un layout donde no todas las flechas estén libres desde el inicio (si no, no habría puzzle).

## Cómo ejecutarlo

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable; el proyecto usa Dart `>=3.0.0 <4.0.0`)
- El backend corriendo en `http://localhost:3000` (URL configurada en `lib/adapters/providers.dart`, `apiClientProvider`)

```bash
flutter pub get
```

### Web

```bash
flutter run -d chrome
```

Funciona out-of-the-box en Chrome. Si el backend corre en otra URL/host, cambiá `baseUrl` en `lib/adapters/providers.dart` antes de correr.

### Android

```bash
flutter run -d <device-id>      # con un emulador o dispositivo conectado
```

- Si usás un emulador, `http://localhost:3000` no apunta a tu máquina — usá `http://10.0.2.2:3000` (alias especial del emulador Android hacia el host) en `apiClientProvider`.
- Revisar `android/app/src/main/AndroidManifest.xml` tiene el permiso `INTERNET` si vas a probar contra un backend remoto.

### iOS

```bash
cd ios && pod install && cd ..
flutter run -d <device-id>
```

- En simulador, `localhost` sí resuelve al host, no hace falta cambiar la URL.
- En dispositivo físico necesitás la IP de tu máquina en la misma red (ni `localhost` ni `10.0.2.2` van a funcionar) y firmar con un team de Apple Developer en Xcode. Hay notas adicionales en `RUN_iOS.md`.

### Backend

Este cliente no funciona solo: necesita `arrowMaze-backend` levantado (seed de niveles, auth, leaderboard). Ver el README de ese repo para correrlo.

## Qué está hecho

- **Juego completo**: carga de nivel, generación de flechas, detección de bloqueos (`BoardGraph`), activar/sacar flecha, animación de salida (slide-off-board), victoria por tablero vacío, derrota por sin-movimientos o por deadlock (sin flechas activables).
- **15 niveles** con figuras reconocibles (cuadrado, diamante, cruz, corazón, letras T/L, flecha, casa, corona, estrella, rayo, reloj de arena, escudo, pacman, espiral), escalando de ~50 a ~100 celdas de fácil a difícil.
- **Auth básico**: login y registro contra el backend (sin validación de campos todavía — ver pendientes).
- **Selección de nivel** con grilla y estado de completado/mejor puntaje por nivel.
- **HUD de partida**: nivel + dificultad centrados, contador de movimientos.
- **Pausa**: overlay con reiniciar tablero, volver al inicio, y toggles de sonido/música/vibración (sonido funcional vía `IAudioService`; música y vibración son toggles de UI sin servicio real todavía).
- **Leaderboard por nivel** (no global — ver pendientes).
- **Persistencia de progreso** local (`sqflite`) con sincronización a backend (`SyncProgressUseCase`).
- **i18n** en/es con un sistema de traducción propio (`AppLocalizations`), no el tooling estándar de Flutter.
- **Restyle visual** de flechas estilo SayGames: trazos delgados, punta proporcional, degradado a lo largo de todo el cuerpo.
- **Power-ups a nivel de dominio** (Hint, Hammer, Magnet) con su caso de uso (`UsePowerUpUseCase`), pero los botones en pantalla de juego todavía no están conectados (`onPressed: () {}`).

## Qué falta (pendiente)

Lista de trabajo priorizada que dejó el equipo:

- [ ] **Precarga de niveles**: cargar al menos 2 niveles por adelantado al seleccionar uno (o preguntar al usuario al inicio si quiere descargar todos de una vez) — hoy cada nivel se genera/carga on-demand y tarda.
- [ ] **Desbloqueo progresivo de niveles** a medida que se completan (hoy todos están abiertos desde el inicio).
- [ ] **Cronómetro** en niveles difíciles (`GameSession.timeRemaining`/`tick()` ya existen en el dominio, pero ningún nivel se carga como `isTimed()`).
- [ ] **Cálculo de score real** (hoy `GameSession.score` suma puntos fijos por movimiento exitoso/fallido; falta una fórmula final con tiempo, movimientos restantes, etc.).
- [ ] **Sistema de vidas**.
- [ ] **Comodines jugables**: conectar los botones de Hint/Hammer/Magnet de `GameScreen` al `UsePowerUpUseCase` que ya existe en el dominio.
- [ ] **Botón de ver contraseña** en login/registro.
- [ ] **Face ID** (login biométrico).
- [ ] **Validaciones de inicio de sesión** (campos vacíos, formato de email, feedback de error en `LoginScreen`/`RegisterScreen`).
- [ ] **Perfil del jugador** (pantalla con estadísticas, niveles completados, etc. — no existe todavía).
- [ ] **Clasificación global** (hoy `LeaderboardScreen` solo muestra el ranking de un nivel a la vez).
- [ ] **Música y vibración reales**: los toggles del overlay de pausa ya están en la UI, falta el servicio detrás (hoy solo el de sonido está conectado a `IAudioService`).

## Tests

```bash
flutter test
```

> Nota: `test/adapters/notifiers_test.dart` y `test/adapters/repositories_test.dart` están rotos (mocks faltantes/desactualizados) — son preexistentes, no relacionados a cambios recientes en `lib/`.
