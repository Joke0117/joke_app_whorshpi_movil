import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioHandlerService extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final Map<String, AudioSource> _audioCache = {};

  AudioHandlerService() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  Future<void> preloadNotes(List<String> assetPaths) async {
    for (final path in assetPaths) {
      _audioCache[path] = AudioSource.asset(path);
    }
  }

  Future<void> playNote(String assetPath) async {
    final source = _audioCache[assetPath];
    if (source != null) {
      await _player.setAudioSource(source, preload: true);
      _player.setLoopMode(LoopMode.one);
      _player.play();
    }
  }

  Future<void> stopNote() async {
    await _player.stop();
  }

  bool isPlaying() => _player.playing;

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.stop,
        ],
        playing: _player.playing,
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });
  }
}