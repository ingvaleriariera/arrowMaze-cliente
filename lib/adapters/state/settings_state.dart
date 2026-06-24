class SettingsState {
  final bool isMuted;

  const SettingsState({
    this.isMuted = false,
  });

  SettingsState copyWith({
    bool? isMuted,
  }) {
    return SettingsState(
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
