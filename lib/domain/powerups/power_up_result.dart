class PowerUpResult {
  final bool success;
  final String message;
  final String? affectedArrowId;

  PowerUpResult({
    required this.success,
    required this.message,
    this.affectedArrowId,
  });

  static PowerUpResult applySuccess(String message, {String? affectedArrowId}) =>
      PowerUpResult(
        success: true,
        message: message,
        affectedArrowId: affectedArrowId,
      );

  static PowerUpResult applyFailure(String message) =>
      PowerUpResult(success: false, message: message);

  @override
  String toString() => 'PowerUpResult(success: $success, message: $message)';
}
