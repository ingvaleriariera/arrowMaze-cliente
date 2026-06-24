class TimeLimit {
  final int seconds;

  const TimeLimit._(this.seconds);

  static const TimeLimit none = TimeLimit._(0);

  factory TimeLimit.of(int seconds) {
    if (seconds < 0) {
      throw ArgumentError('Seconds must be non-negative');
    }
    return TimeLimit._(seconds);
  }

  bool hasLimit() => seconds > 0;

  int getValue() => seconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLimit && seconds == other.seconds;

  @override
  int get hashCode => seconds.hashCode;

  @override
  String toString() => 'TimeLimit($seconds seconds)';
}
