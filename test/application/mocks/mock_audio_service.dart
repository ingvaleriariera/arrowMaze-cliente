import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';

class MockAudioService implements IAudioService {
  final List<String> playedEffects = [];
  final List<String> playedMusic = [];
  bool _isMuted = false;

  @override
  Future<void> playEffect(String sound) async {
    if (!_isMuted) {
      playedEffects.add(sound);
    }
  }

  @override
  Future<void> playMusic(String track) async {
    if (!_isMuted) {
      playedMusic.add(track);
    }
  }

  @override
  Future<void> stopMusic() async {
    // No-op for mock
  }

  @override
  void mute() {
    _isMuted = true;
  }

  @override
  void unmute() {
    _isMuted = false;
  }

  @override
  bool isMuted() => _isMuted;
}
