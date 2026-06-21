# Arrow Maze — Cliente (Flutter)

Clon del juego **Arrow Maze** (SayGames). Puzzle donde el jugador activa
flechas para que salgan del tablero. Una flecha solo puede salir si su
camino hasta el borde (o una celda *void*) está libre de otras flechas.

- **Stack:** Flutter + Riverpod (Dart)
- **Backend:** NestJS + Supabase (PostgreSQL) — repo separado:
  [`arrowMaze-backend`](../arrowMaze-backend)
- **Arquitectura:** Clean Architecture en 4 capas (ver
  [Arquitectura](#arquitectura))

---

## Requisitos

| Herramienta | Versión usada en desarrollo |
|---|---|
| Flutter    | 3.44.2 (channel stable) |
| Dart SDK   | 3.12.2 (incluido con Flutter) |
| Node.js    | 20.x (para correr el backend) |
| Chrome     | Cualquier versión reciente (para `flutter run -d chrome`) |

Verifica tu instalación de Flutter:

```bash
flutter --version
flutter doctor
```

---

## 1. Levantar el backend (requerido)

El cliente **no funciona sin el backend** corriendo en
`http://localhost:3000`. Clona y arranca `arrowMaze-backend` por separado:

```bash
cd ../arrowMaze-backend
cp .env.template .env       # completa DB_HOST, DB_USERNAME, DB_PASSWORD,
                             # DB_NAME, JWT_SECRET, JWT_EXPIRES_IN, PORT
npm install
npm run start:dev
```

Deberías ver en la terminal:

```
🚀 Servidor corriendo en: http://localhost:3000/api/v1
📝 Documentación Swagger en: http://localhost:3000/api/docs
```

Verifica que responde:

```bash
curl http://localhost:3000/api/v1/levels
```

> **CORS:** el backend ya tiene `app.enableCors(...)` habilitado en
> `src/main.ts` (origin `*`), necesario para probar el cliente en
> Flutter Web (Chrome). Si vuelves a clonar el backend desde cero y no
> está presente, agrégalo antes de `app.listen()`.

---

## 2. Instalar dependencias del cliente

```bash
flutter pub get
```

---

## 3. Correr la app

### Opción A — Mobile (Android / iOS)

Es el target principal del proyecto (ver `.metadata`, plataformas
restringidas a `android` e `ios`).

```bash
flutter run -d <device-id>      # flutter devices para listar
```

### Opción B — Web (Chrome), para probar mientras se configura el simulador

El proyecto incluye soporte experimental para Flutter Web (carpeta
`web/`), pensado para iterar rápido sin esperar a Xcode/Android Studio.

```bash
flutter run -d chrome --web-port=8765
```

Si es la **primera vez** que corres web en una máquina nueva, sqflite
necesita binarios adicionales para funcionar en el navegador (IndexedDB
en vez de SQLite nativo). Si ves el error
`SqfliteFfiWebException` / *"failure to find the worker javascript file
at sqflite_sw.js"*, corre una sola vez:

```bash
dart run sqflite_common_ffi_web:setup
```

Esto descarga `web/sqlite3.wasm` y `web/sqflite_sw.js` (ya están
commiteados en este repo, así que normalmente **no** necesitas correr
esto salvo que los borres o actualices la dependencia).

> **Nota:** el desenfoque visual de las flechas en Flutter Web (canvas)
> es un tema pendiente, de menor prioridad — se retomará junto con las
> pruebas en simulador iOS/Xcode.

---

## 4. Probar el flujo completo

1. Abre la app (Chrome o el dispositivo/simulador).
2. **Registro:** en la pantalla de login, ve a "Register" y crea un
   usuario (`email`, `username`, `password`). Esto llama a
   `POST /api/v1/auth/register` y guarda el JWT + `userId` localmente
   (`flutter_secure_storage`).
3. Tras registrarte entras a **Selección de nivel** (`/levels`), que
   lista los niveles del backend (`GET /api/v1/levels`) con tu progreso
   local (sqflite).
4. Toca un nivel para entrar al tablero. Las flechas se generan
   **proceduralmente en el cliente** a partir del `boardLayout` (JSON
   de celdas válidas) — el backend no envía flechas, solo la forma del
   tablero.
5. Toca una flecha:
   - Si su camino de salida está libre, sale del tablero (animación).
   - Si está bloqueada, parpadea en rojo y se penaliza el score.
6. Al vaciar el tablero (`VICTORY`) o agotar movimientos/tiempo
   (`DEFEAT`), navega a la pantalla correspondiente.

Para volver a probar como usuario nuevo, cierra sesión (ícono de logout
en `/levels`) o borra el `localStorage` del sitio (`Application →
Storage → Clear site data` en DevTools) si estás en Chrome.

---

## 5. Tests y análisis estático

```bash
flutter analyze     # debe salir "No issues found!"
flutter test        # corre test/widget_test.dart
```

---

## Arquitectura

Clean Architecture estricta en 4 capas — las dependencias solo apuntan
hacia adentro (Capa 4 → 3 → 2 → 1, nunca al revés). **No** se usa DDD
(sin `@AggregateRoot`/`@Entity`/`@ValueObject`); son clases Dart
normales.

```
lib/
  domain/        Capa 1 — lógica pura, cero dependencias externas
  application/   Capa 2 — casos de uso, orquesta el dominio
  adapters/      Capa 3 — Riverpod notifiers, repos concretos, ApiClient
  ui/            Capa 4 — widgets Flutter, screens, router, interceptores
```

Diagramas PlantUML por capa en [`docs/`](docs):
`client_layer1_domain.puml`, `client_layer2_application.puml`,
`client_layer3_adapters.puml`, `client_layer4_frameworks.puml`.

Referencia visual del juego (prototipo HTML/Canvas, usado como fuente
de verdad para el motor y el dibujo del tablero):
[`docs/arrow_maze_v5.html`](docs/arrow_maze_v5.html) — ábrelo
directamente en un navegador.

Documentación completa de convenciones, patrones GoF y contratos de
API: [`CLAUDE.md`](CLAUDE.md).

---

## Endpoints del backend usados por el cliente

| Método | Endpoint | Auth | Notas |
|---|---|---|---|
| POST | `/auth/register` | No | `{email, username, password}` → `{userId, username, token}` |
| POST | `/auth/login` | No | `{email, password}` → `{userId, username, token}` |
| GET  | `/levels` | No | Devuelve **todos** los niveles (no hay `/levels/:id`) |
| POST | `/scores/submit` | Bearer | `{userId, levelId, score}` |
| POST | `/progress/sync` | Bearer | Sincroniza progreso local ↔ backend |
| GET  | `/leaderboard/:levelId` | No | Top scores de un nivel |

Base URL configurada en `lib/adapters/api/api_client.dart`:
`http://localhost:3000/api/v1`.

---

## Problemas conocidos / pendientes

- **Variedad visual de flechas** (tamaños y curvaturas distintas como en
  `docs/arrow_maze_v5.html`): pendiente de definir primero el formato
  JSON de creación de niveles en el backend.
- **Desenfoque en Flutter Web:** pendiente, baja prioridad — se
  retomará al probar en simulador iOS.

## Troubleshooting rápido

| Síntoma | Causa probable | Solución |
|---|---|---|
| `ApiException(null): Unknown network error` en web | CORS no habilitado en el backend | Verifica `app.enableCors(...)` en `arrowMaze-backend/src/main.ts` |
| `Bad state: databaseFactory not initialized` en web | Falta el factory de sqflite para web | Ya manejado en `lib/main.dart` vía `kIsWeb` — si persiste, corre `dart run sqflite_common_ffi_web:setup` |
| `Address already in use` al correr `flutter run -d chrome` | Ya hay un proceso de Flutter corriendo en ese puerto | `lsof -ti:8765 \| xargs kill -9` (ajusta el puerto) o usa otro `--web-port` |
| Niveles ya jugados muestran score en uno que no jugaste | Sesión vieja sin `userId` restaurado (bug corregido) | Asegúrate de tener el último `develop`; si persiste, cierra sesión y vuelve a loguearte |
