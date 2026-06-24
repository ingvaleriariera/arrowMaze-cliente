abstract class IAudioService {
  Future<void> playEffect(String sound);
  Future<void> playMusic(String track);
  Future<void> stopMusic();
  void mute();
  void unmute();
  bool isMuted();
}
