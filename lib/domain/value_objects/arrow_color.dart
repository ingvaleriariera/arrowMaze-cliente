class ArrowColor {
  final String value;

  ArrowColor._(this.value);

  static ArrowColor fromHex(String hex) => ArrowColor._(hex);

  String getValue() => value;

  bool equals(ArrowColor other) => value == other.value;
}
