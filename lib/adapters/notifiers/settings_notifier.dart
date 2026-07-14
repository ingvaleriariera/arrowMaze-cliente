import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/settings_state.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final IAudioService audioService;

  SettingsNotifier({required this.audioService})
      : super(SettingsState(isMuted: audioService.isMuted()));

  void toggleMute() {
    if (state.isMuted) {
      audioService.unmute();
      state = state.copyWith(isMuted: false);
    } else {
      audioService.mute();
      state = state.copyWith(isMuted: true);
    }
  }

  void toggleMusic() {
    state = state.copyWith(musicEnabled: !state.musicEnabled);
  }

  void toggleVibration() {
    state = state.copyWith(vibrationEnabled: !state.vibrationEnabled);
  }

  void toggleBoard3D() {
    state = state.copyWith(board3DEnabled: !state.board3DEnabled);
  }

  void toggleGame3D() {
    state = state.copyWith(game3DEnabled: !state.game3DEnabled);
  }
}
