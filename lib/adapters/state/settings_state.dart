class SettingsState {
  final bool isMuted;
  // Presentation-only toggles — no backing music/haptics service exists
  // yet, but they're now a single shared source of truth (SettingsScreen
  // and GameScreen's pause overlay both read/write these instead of each
  // keeping their own disconnected local state).
  final bool musicEnabled;
  final bool vibrationEnabled;

  /// Renders the game board through the 3D perspective viewport (tilt +
  /// finger rotation) instead of the flat top-down view. Purely a
  /// presentation-layer swap: gameplay, domain and use cases are
  /// identical in both modes.
  final bool board3DEnabled;

  /// The 6-connection 3D GAME (not just the view): boards are extruded
  /// into 4-layer prisms, arrows can travel and exit along the Z axis,
  /// and GameScreen shows a layer selector to see/tap each floor.
  final bool game3DEnabled;

  const SettingsState({
    this.isMuted = false,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.board3DEnabled = false,
    this.game3DEnabled = false,
  });

  SettingsState copyWith({
    bool? isMuted,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? board3DEnabled,
    bool? game3DEnabled,
  }) {
    return SettingsState(
      isMuted: isMuted ?? this.isMuted,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      board3DEnabled: board3DEnabled ?? this.board3DEnabled,
      game3DEnabled: game3DEnabled ?? this.game3DEnabled,
    );
  }
}
