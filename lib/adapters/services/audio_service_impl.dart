import 'package:just_audio/just_audio.dart';

import '../../application/ports/i_audio_service.dart';

class AudioServiceImpl implements IAudioService {
  final AudioPlayer _effectPlayer;
  final AudioPlayer _musicPlayer;
  bool _isMuted = false;

  AudioServiceImpl({AudioPlayer? effectPlayer, AudioPlayer? musicPlayer})
      : _effectPlayer = effectPlayer ?? AudioPlayer(),
        _musicPlayer = musicPlayer ?? AudioPlayer();

  @override
  void playEffect(String sound) {
    if (_isMuted) return;
    _effectPlayer.setAsset('assets/sounds/$sound.mp3');
    _effectPlayer.play();
  }

  @override
  void playMusic(String track) {
    if (_isMuted) return;
    _musicPlayer.setAsset('assets/music/$track.mp3');
    _musicPlayer.play();
  }

  @override
  void stopMusic() {
    _musicPlayer.stop();
  }

  @override
  void mute() {
    _isMuted = true;
    _musicPlayer.setVolume(0);
  }

  @override
  void unmute() {
    _isMuted = false;
    _musicPlayer.setVolume(1);
  }

  @override
  bool isMuted() => _isMuted;
}
