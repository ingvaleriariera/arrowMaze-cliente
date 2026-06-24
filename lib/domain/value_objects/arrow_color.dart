class ArrowColor {
  final String value;

  const ArrowColor._(this.value);

  static ArrowColor fromHex(String hex) {
    // Validate hex format
    final normalized = hex.startsWith('#') ? hex : '#$hex';
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(normalized)) {
      throw ArgumentError('Invalid hex color format: $hex');
    }
    return ArrowColor._(normalized.toLowerCase());
  }

  bool equals(ArrowColor other) => value == other.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowColor && equals(other);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ArrowColor($value)';
}
