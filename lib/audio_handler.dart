import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'main.dart' show audioArtworkPath;

class AudioHandlerService extends BaseAudioHandler with SeekHandler {
  final _player1 = AudioPlayer();
  final _player2 = AudioPlayer();

  bool _usePlayer1 = true;
  String _currentNote = '';
  MediaItem? _lastMediaItem;

  static const fadeDuration = Duration(milliseconds: 1500);

  AudioHandlerService() {
    _listenToPlaybackEvents(_player1);
    _listenToPlaybackEvents(_player2);
    _updatePlaybackState();
  }

  // ── Precarga de assets ──────────────────────────────────────────────────
  Future<void> preloadNotes(List<String> assetPaths) async {
    // just_audio carga los assets locales instantáneamente,
    // no requiere caché de AudioSource (de hecho, reutilizarlo causa crasheos).
  }

  // ── Construir artUri correctamente ─────────────────────────────────────
  /// Devuelve un Uri de archivo en disco (accesible por notificaciones nativas).
  /// Si aún no se copió la imagen al disco, usa null y Android usará el ícono
  /// de launcher como fallback.
  Uri? _buildArtUri() {
    final path = audioArtworkPath;
    if (path != null && File(path).existsSync()) {
      return Uri.file(path);
    }
    return null;
  }

  // ── Reproducir nota con Crossfade ─────────────────────────────────────────
  Future<void> playNote(String assetPath) async {
    final raw = assetPath.split('/').last.replaceAll('.mp3', '');
    final display = raw.replaceAll('sharp', '#');
    _currentNote = display;

    // Actualizar notificación del sistema
    final item = MediaItem(
      id: assetPath,
      title: 'Pad: $display',
      artist: 'Pad Worship',
      album: 'Pad Worship by Joke',
      displayTitle: 'Pad Worship',
      displaySubtitle: display,
      // FIX: usar artUri con archivo en disco (los assets de Flutter no son
      // accesibles por la notificación nativa del SO)
      artUri: _buildArtUri(),
      playable: true,
      duration: const Duration(minutes: 10),
    );
    _lastMediaItem = item;
    mediaItem.add(item);

    // FIX: emitir estado "playing" INMEDIATAMENTE antes del crossfade para que
    // la notificación y el MiniPlayer aparezcan sin esperar eventos del player
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause, MediaControl.stop],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));

    final activePlayer = _usePlayer1 ? _player1 : _player2;
    final nextPlayer = _usePlayer1 ? _player2 : _player1;

    try {
      // Configurar el nuevo reproductor a volumen 0
      // Es VITAL crear un nuevo AudioSource.asset() cada vez para evitar el StateError
      await nextPlayer.setAudioSource(AudioSource.asset(assetPath), preload: true);
      await nextPlayer.setLoopMode(LoopMode.one);
      await nextPlayer.setVolume(0.0);
      nextPlayer.play();

      // Iniciar Crossfade
      _crossfade(activePlayer, nextPlayer);

      // Cambiar el reproductor activo para la próxima vez
      _usePlayer1 = !_usePlayer1;
    } catch (e) {
      print('Error reproduciendo pad $assetPath: $e');
    }
  }

  // ── Lógica matemática del Crossfade ──────────────────────────────────────
  void _crossfade(AudioPlayer fadeOutPlayer, AudioPlayer fadeInPlayer) {
    const steps = 30;
    final stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps);
    double volumeStep = 1.0 / steps;

    int currentStep = 0;
    Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      double newInVol = currentStep * volumeStep;
      double newOutVol = 1.0 - newInVol;

      // Asegurarse de no exceder los límites
      if (newInVol > 1.0) newInVol = 1.0;
      if (newOutVol < 0.0) newOutVol = 0.0;

      fadeInPlayer.setVolume(newInVol);
      if (fadeOutPlayer.playing) {
        fadeOutPlayer.setVolume(newOutVol);
      }

      if (currentStep >= steps) {
        timer.cancel();
        fadeInPlayer.setVolume(1.0);
        await fadeOutPlayer.stop();
      }
    });
  }

  // ── Parar (Fade Out general) ─────────────────────────────────────────────
  @override
  Future<void> stop() async {
    _currentNote = '';
    // No limpiamos mediaItem — la notificación debe quedarse visible
    // como en Spotify, para poder reanudar desde ahí
    _fadeOutAndStop(_player1);
    _fadeOutAndStop(_player2);
    _updatePlaybackState();
    await super.stop();
  }

  void _fadeOutAndStop(AudioPlayer player) {
    if (!player.playing) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps);
    double currentVol = player.volume;
    double volumeStep = currentVol / steps;

    Timer.periodic(stepDuration, (timer) async {
      currentVol -= volumeStep;
      if (currentVol <= 0.0) {
        timer.cancel();
        player.setVolume(0.0);
        await player.stop();
      } else {
        player.setVolume(currentVol);
      }
    });
  }

  // ── Pausar / Reanudar ───────────────────────────────────────────────────
  @override
  Future<void> pause() async {
    if (_player1.playing) await _player1.pause();
    if (_player2.playing) await _player2.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> play() async {
    // Si el mediaItem fue limpiado, restaurar el último para que la
    // notificación tenga contenido que mostrar
    if (mediaItem.value == null && _lastMediaItem != null) {
      mediaItem.add(_lastMediaItem);
    }
    final activePlayer = _usePlayer1 ? _player1 : _player2;
    if (activePlayer.audioSource == null) {
      // Si el player activo no tiene fuente, probar con el otro
      final other = _usePlayer1 ? _player2 : _player1;
      if (other.audioSource != null) {
        await other.play();
        return;
      }
      return;
    }
    await activePlayer.play();
  }

  // Cuando el usuario cierra la app (swipe), solo pausamos
  // para que la notificación continúe visible como en Spotify
  @override
  Future<void> onTaskRemoved() async {
    await pause();
  }

  Future<void> stopNote() async => stop();
  bool isPlaying() => _player1.playing || _player2.playing;
  String get currentNote => _currentNote;

  // Modificamos el stream para que notifique si alguno de los dos está sonando
  Stream<bool> get playingStream {
    return _player1.playingStream; // Simplificado temporalmente
  }

  // Stream para obtener la posición exacta del audio actual (para la barra de progreso real)
  Stream<Duration> get positionStream => Stream.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (_player1.playing) return _player1.position;
          if (_player2.playing) return _player2.position;
          return Duration.zero;
        },
      );

  // ── Eventos del sistema unificados ─────────────────────────────────────────
  void _listenToPlaybackEvents(AudioPlayer player) {
    player.playbackEventStream.listen((event) => _updatePlaybackState());
  }

  void _updatePlaybackState() {
    final playing = _player1.playing || _player2.playing;

    // FIX: calcular el estado de procesamiento correctamente.
    // Nunca debe quedar en 'idle' si hay un player cargado o reproduciendo.
    // Prioridad: loading > buffering > ready > idle
    AudioProcessingState combinedState;

    if (_player1.processingState == ProcessingState.loading ||
        _player2.processingState == ProcessingState.loading) {
      combinedState = AudioProcessingState.loading;
    } else if (_player1.processingState == ProcessingState.buffering ||
        _player2.processingState == ProcessingState.buffering) {
      combinedState = AudioProcessingState.buffering;
    } else if (_player1.processingState == ProcessingState.ready ||
        _player2.processingState == ProcessingState.ready ||
        _player1.playing ||
        _player2.playing) {
      // FIX: si algún player está reproduciendo o listo, el estado es 'ready'
      // aunque el otro esté en idle (situación habitual durante el crossfade)
      combinedState = AudioProcessingState.ready;
    } else if (_player1.processingState == ProcessingState.completed ||
        _player2.processingState == ProcessingState.completed) {
      combinedState = AudioProcessingState.completed;
    } else {
      // Ambos players en idle: realmente no hay audio cargado
      combinedState = AudioProcessingState.idle;
    }

    // El jugador activo real es el que tiene volumen > 0 o el último configurado
    final activePlayer = _player1.volume > _player2.volume ? _player1 : _player2;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      playing: playing,
      updatePosition: activePlayer.position,
      bufferedPosition: activePlayer.bufferedPosition,
      speed: activePlayer.speed,
      processingState: combinedState,
    ));
  }
}
