import 'package:flutter_riverpod/legacy.dart';

import '../../application/ports/i_audio_service.dart';

class SettingsNotifier extends StateNotifier<bool> {
  final IAudioService audioService;

  SettingsNotifier(this.audioService) : super(audioService.isMuted());

  void toggleMute() {
    if (state) {
      audioService.unmute();
    } else {
      audioService.mute();
    }
    state = audioService.isMuted();
  }

  bool getIsMuted() => state;
}
