/// Centralizada configuración de API para la capa de infraestructura.
///
/// [apiBaseUrl] NUNCA debe hardcodearse aquí con una IP personal — cada
/// vez que alguien del equipo prueba en su propio teléfono y comitea ese
/// cambio, pisa la IP de quien lo hizo antes (ya pasó más de una vez).
/// En vez de eso, se lee de una variable de entorno de compilación:
///
///   flutter run --dart-define-from-file=local.env.json
///
/// donde `local.env.json` (gitignored, ver local.env.json.example) tiene:
///   { "API_BASE_URL": "http://TU_IP_LOCAL:3000" }
///
/// Sin ese archivo, cae en el default de abajo (sirve para el simulador
/// de iOS, que sí puede usar localhost).
class ApiConfig {
  /// URL base del servidor NestJS backend
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Puerto del servidor API
  static const int apiPort = 3000;

  /// Protocolo (http o https)
  static const String apiProtocol = 'http';

  /// Host/IP del servidor API
  static const String apiHost = '192.168.0.3';

  /// Timeout para requests HTTP (en segundos)
  static const int requestTimeoutSeconds = 30;

  /// Timeout para conexión (en segundos)
  static const int connectionTimeoutSeconds = 10;
}
