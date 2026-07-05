class PowerUpResult {
  final bool success;
  final String message;
  final List<String> affectedArrowIds;

  PowerUpResult({
    required this.success,
    required this.message,
    this.affectedArrowIds = const [],
  });

  static PowerUpResult applySuccess(String message,
          {List<String> affectedArrowIds = const []}) =>
      PowerUpResult(
        success: true,
        message: message,
        affectedArrowIds: affectedArrowIds,
      );

  static PowerUpResult applyFailure(String message) =>
      PowerUpResult(success: false, message: message);

  @override
  String toString() => 'PowerUpResult(success: $success, message: $message)';
}
