class SettingsState {
  final bool isMuted;
  final bool vibrationEnabled;

  /// Renders the game board through the 3D perspective viewport (tilt +
  /// finger rotation) instead of the flat top-down view. Purely a
  /// presentation-layer swap: gameplay, domain and use cases are
  /// identical in both modes.
  final bool board3DEnabled;

  /// The 6-connection 3D GAME (not just the view): boards are extruded
  /// into 4-layer prisms, arrows can travel and exit along the Z axis,
  final bool game3DEnabled;

  const SettingsState({
    this.isMuted = false,
    this.vibrationEnabled = true,
    this.board3DEnabled = false,
    this.game3DEnabled = false,
  });

  SettingsState copyWith({
    bool? isMuted,
    bool? vibrationEnabled,
    bool? board3DEnabled,
    bool? game3DEnabled,
  }) {
    return SettingsState(
      isMuted: isMuted ?? this.isMuted,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      board3DEnabled: board3DEnabled ?? this.board3DEnabled,
      game3DEnabled: game3DEnabled ?? this.game3DEnabled,
    );
  }
}
