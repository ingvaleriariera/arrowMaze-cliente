/// Centralizada configuración de API para la capa de infraestructura.
///
/// Actualiza [apiBaseUrl] aquí cuando la IP del backend cambia.
/// Ejemplo: de '192.168.0.3' a '172.16.0.146' según la red WiFi.
class ApiConfig {
  /// URL base del servidor NestJS backend
  static const String apiBaseUrl = 'http://192.168.0.3:3000';

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
