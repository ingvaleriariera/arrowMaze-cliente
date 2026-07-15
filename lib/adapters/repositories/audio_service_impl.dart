import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';

/// Singleton audio service implementation using just_audio.
/// Manages two separate AudioPlayers:
/// - _musicPlayer: background music with looping
/// - _effectsPlayer: one-shot sound effects
///
/// Ensures mute state applies to both players simultaneously.
class AudioServiceImpl implements IAudioService {
  // Singleton pattern
  static final AudioServiceImpl _instance = AudioServiceImpl._internal();

  factory AudioServiceImpl() {
    return _instance;
  }

  AudioServiceImpl._internal();

  // Audio players: separate instances for music and effects
  late final AudioPlayer _musicPlayer = AudioPlayer();
  late final AudioPlayer _effectsPlayer = AudioPlayer();

  // Mute state (in-memory; persisted to SharedPreferences in a future phase)
  bool _isMuted = false;
  String? _currentMusicTrack;

  // Last track requested through playMusic(), kept even when the actual
  // play() call failed. On Web, the very first playMusic() call happens on
  // page load (no user gesture), so browser autoplay policies (Chrome,
  // Safari) commonly reject it and music never starts. unmute() is called
  // synchronously from the switch's onChanged — a real user gesture — so it
  // retries playback from there, which the browser allows.
  String? _lastRequestedTrack;

  /// Get the asset path for a given sound identifier.
  String _getAssetPath(String sound) {
    return 'assets/audio/$sound.mp3';
  }

  @override
  Future<void> playEffect(String sound) async {
    if (_isMuted) {
      debugPrint('🔇 AudioServiceImpl: Effect "$sound" blocked (muted)');
      return;
    }

    try {
      debugPrint('🔊 AudioServiceImpl: Playing effect "$sound"');
      final assetPath = _getAssetPath(sound);

      // Stop any currently playing effect first
      await _effectsPlayer.stop();

      // Set effect player to NOT loop
      await _effectsPlayer.setLoopMode(LoopMode.off);

      // Set lower volume for effects (e.g., 0.8) to not overwhelm music
      await _effectsPlayer.setVolume(0.8);

      // Load and play the effect asset
      await _effectsPlayer.setAsset(assetPath);
      await _effectsPlayer.play();

      debugPrint('✅ AudioServiceImpl: Effect "$sound" started');
    } catch (e) {
      debugPrint('❌ AudioServiceImpl.playEffect: Error playing "$sound" - $e');
    }
  }

  @override
  Future<void> playMusic(String track) async {
    _lastRequestedTrack = track;

    if (_isMuted) {
      debugPrint('🔇 AudioServiceImpl: Music "$track" blocked (muted)');
      return;
    }

    // If the same track is already playing — or already being started by
    // an in-flight call — do nothing. Home and LevelSelectScreen both call
    // this on every mount (e.g. every tab switch), so without claiming the
    // track BEFORE the first await, two near-simultaneous calls could both
    // pass this check and race each other's stop()+play() — audibly
    // restarting the track on every switch instead of a clean no-op.
    if (_currentMusicTrack == track) {
      debugPrint('ℹ️  AudioServiceImpl: Music "$track" already playing, skipping');
      return;
    }
    final previousTrack = _currentMusicTrack;
    _currentMusicTrack = track;

    try {
      debugPrint('🎵 AudioServiceImpl: Playing music "$track"');
      final assetPath = _getAssetPath(track);

      // Stop current music first if something is playing
      if (previousTrack != null) {
        await _musicPlayer.stop();
      }

      // Set music player to LOOP
      await _musicPlayer.setLoopMode(LoopMode.one);

      // Set higher volume for background music (e.g., 1.0)
      await _musicPlayer.setVolume(1.0);

      // Load and play the music asset
      await _musicPlayer.setAsset(assetPath);
      await _musicPlayer.play();

      debugPrint('✅ AudioServiceImpl: Music "$track" started (looping)');
    } catch (e) {
      debugPrint('❌ AudioServiceImpl.playMusic: Error playing "$track" - $e');
      // Roll back so a later retry isn't permanently deduped against a
      // track that never actually started.
      if (_currentMusicTrack == track) {
        _currentMusicTrack = previousTrack;
      }
    }
  }

  @override
  Future<void> stopMusic() async {
    try {
      debugPrint('⏹️  AudioServiceImpl: Stopping music');
      await _musicPlayer.stop();
      _currentMusicTrack = null;
      debugPrint('✅ AudioServiceImpl: Music stopped');
    } catch (e) {
      debugPrint('❌ AudioServiceImpl.stopMusic: Error - $e');
    }
  }

  @override
  void mute() {
    if (_isMuted) return; // Already muted
    _isMuted = true;
    debugPrint('🔇 AudioServiceImpl: Muted');

    // Set volume to 0 for both players
    _musicPlayer.setVolume(0.0);
    _effectsPlayer.setVolume(0.0);
  }

  @override
  void unmute() {
    if (!_isMuted) return; // Already unmuted
    _isMuted = false;
    debugPrint('🔊 AudioServiceImpl: Unmuted');

    // Restore volumes for both players
    _musicPlayer.setVolume(1.0);
    _effectsPlayer.setVolume(0.8);

    // If music never actually started (e.g. blocked by a browser autoplay
    // policy on the original page-load attempt), retry now: this call
    // originates synchronously from the switch's onChanged, which counts
    // as a user gesture and satisfies the autoplay policy.
    if (!_musicPlayer.playing && _lastRequestedTrack != null) {
      final track = _lastRequestedTrack!;
      _currentMusicTrack = null; // bypass playMusic's already-playing dedup
      playMusic(track).catchError((e) {
        debugPrint('⚠️  AudioServiceImpl.unmute: Retry failed to start music - $e');
      });
    }
  }

  @override
  bool isMuted() => _isMuted;

  /// Dispose resources. Call this during app shutdown.
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _effectsPlayer.dispose();
  }
}
