import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';

class AudioServiceImpl implements IAudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  late SharedPreferences _prefs;

  static const String _muteKey = 'audio_muted';

  bool _isMuted = false;

  AudioServiceImpl({SharedPreferences? prefs}) {
    if (prefs != null) {
      _prefs = prefs;
      _isMuted = prefs.getBool(_muteKey) ?? false;
    }
  }

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isMuted = prefs.getBool(_muteKey) ?? false;
  }

  @override
  Future<void> playEffect(String sound) async {
    if (_isMuted) return;
    try {
      // In a real app, map sound names to actual files
      // For now, this is a no-op since we don't have actual audio files
    } catch (e) {
      print('Error playing effect: $e');
    }
  }

  @override
  Future<void> playMusic(String track) async {
    if (_isMuted) return;
    try {
      // In a real app, play music file and set looping
      await _musicPlayer.setLoopMode(LoopMode.one);
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  @override
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  @override
  void mute() {
    _isMuted = true;
    if (_prefs != null) {
      _prefs.setBool(_muteKey, true);
    }
  }

  @override
  void unmute() {
    _isMuted = false;
    if (_prefs != null) {
      _prefs.setBool(_muteKey, false);
    }
  }

  @override
  bool isMuted() => _isMuted;
}
