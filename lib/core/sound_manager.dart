import 'package:audioplayers/audioplayers.dart';
import 'dart:developer';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Start playing the request sound in a loop
  Future<void> startRequestSound() async {
    if (_isPlaying) return;
    
    try {
      log('🔊 Starting request sound loop...');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sound.mp3'));
      _isPlaying = true;
    } catch (e) {
      log('❌ Error playing request sound: $e');
    }
  }

  /// Stop the request sound
  Future<void> stopRequestSound() async {
    if (!_isPlaying) return;
    
    try {
      log('🔇 Stopping request sound.');
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      log('❌ Error stopping request sound: $e');
    }
  }

  /// Dispose the player when no longer needed
  void dispose() {
    _audioPlayer.dispose();
  }
}
