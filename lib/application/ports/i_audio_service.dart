/// Audio service port (Application layer).
/// Defines the interface for audio playback and management.
///
/// Implementers must support:
/// - Background music with looping (separate player from effects)
/// - Sound effects without interrupting background music
/// - Mute/unmute state persistence
///
/// Audio files are loaded from assets/audio/:
/// - background_music.mp3: background loop
/// - victory.mp3: victory effect
/// - fiasco.mp3: defeat effect
abstract class IAudioService {
  /// Play a sound effect (one-shot, non-looping).
  /// Does not interrupt background music.
  Future<void> playEffect(String sound);

  /// Play background music with looping.
  /// If the same track is already playing, does nothing.
  /// If a different track is playing, stops it first.
  Future<void> playMusic(String track);

  /// Stop the background music.
  Future<void> stopMusic();

  /// Mute all audio (both music and effects).
  void mute();

  /// Unmute all audio.
  void unmute();

  /// Return whether audio is currently muted.
  bool isMuted();
}
