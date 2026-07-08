class SettingsState {
  final bool isMuted;
  // Presentation-only toggles — no backing music/haptics service exists
  // yet, but they're now a single shared source of truth (SettingsScreen
  // and GameScreen's pause overlay both read/write these instead of each
  // keeping their own disconnected local state).
  final bool musicEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.isMuted = false,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    bool? isMuted,
    bool? musicEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      isMuted: isMuted ?? this.isMuted,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
