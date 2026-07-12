import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_observer.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';
import 'package:flutter/foundation.dart';

/// Adapter that bridges game events (Observer) to audio responses.
/// Implements IGameObserver to listen to GameSession events and trigger
/// appropriate audio effects and background music management.
///
/// This is a concrete adapter in the Adapters layer that implements the
/// Domain port (IGameObserver), allowing Domain logic (GameSession) to remain
/// free of audio concerns. The pairing of GameSession (Subject) + AudioObserver
/// (Listener) demonstrates the GoF Observer pattern.
class AudioObserver implements IGameObserver {
  final IAudioService _audioService;

  AudioObserver(this._audioService);

  @override
  void onPlayerMoved(MoveResult result) {
    // No audio response for individual moves is currently required by the
    // specification. This method is intentionally empty to maintain the
    // Observer interface contract, but can be extended in the future
    // (e.g., to play a "click" or "swish" sound on successful moves).
    // The empty implementation prevents unnecessary audio file lookups
    // and keeps the audio experience clean during gameplay.
    debugPrint('🎮 AudioObserver: Player moved (no sound response)');
  }

  @override
  void onScoreUpdated(int newScore) {
    // No audio response for score updates is currently required.
    // Kept for interface completeness and future extensibility.
    debugPrint('🎮 AudioObserver: Score updated to $newScore (no sound response)');
  }

  @override
  void onLevelCompleted(bool success, int finalScore) async {
    debugPrint('🎮 AudioObserver: Level completed (success=$success, finalScore=$finalScore)');

    // Stop background music when level ends (wait for completion)
    try {
      await _audioService.stopMusic();
    } catch (e) {
      debugPrint('⚠️  AudioObserver: Failed to stop music - $e');
    }

    // Small delay to ensure music player is fully stopped before playing effect
    await Future.delayed(const Duration(milliseconds: 100));

    // Play appropriate effect based on victory or defeat
    if (success) {
      debugPrint('🎉 AudioObserver: Playing victory effect');
      _audioService.playEffect('success').catchError((e) {
        debugPrint('⚠️  AudioObserver: Failed to play victory effect - $e');
      });
    } else {
      debugPrint('💔 AudioObserver: Playing defeat effect');
      _audioService.playEffect('fiasco').catchError((e) {
        debugPrint('⚠️  AudioObserver: Failed to play defeat effect - $e');
      });
    }
  }
}
