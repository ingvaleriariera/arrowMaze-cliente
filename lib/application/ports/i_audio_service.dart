abstract class IAudioService {
  void playEffect(String sound);
  void playMusic(String track);
  void stopMusic();
  void mute();
  void unmute();
  bool isMuted();
}
