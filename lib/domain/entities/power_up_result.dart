class PowerUpResult {
  final bool _success;
  final String? affectedArrowId;
  final String? message;

  PowerUpResult._(this._success, this.affectedArrowId, this.message);

  static PowerUpResult success(String? arrowId) =>
      PowerUpResult._(true, arrowId, null);

  static PowerUpResult failure(String message) =>
      PowerUpResult._(false, null, message);

  bool isSuccess() => _success;
  String? getAffectedArrowId() => affectedArrowId;
}
