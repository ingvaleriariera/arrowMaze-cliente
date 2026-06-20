class TimeLimit {
  final int seconds;

  TimeLimit._(this.seconds);

  static TimeLimit none() => TimeLimit._(0);
  static TimeLimit of(int seconds) => TimeLimit._(seconds);

  int getValue() => seconds;

  bool hasLimit() => seconds > 0;

  bool equals(TimeLimit other) => seconds == other.seconds;
}
