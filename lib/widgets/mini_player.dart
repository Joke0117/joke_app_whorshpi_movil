import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../theme/colors.dart';

/// Mini reproductor flotante — aparece encima del footer cuando hay audio activo.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    // Protección: si audioHandler no está inicializado, no mostrar nada
    try {
      // ignore: unnecessary_null_comparison
      if (audioHandler == null) return const SizedBox.shrink();
    } catch (_) {
      return const SizedBox.shrink();
    }

    // Usamos el stream del handler directamente (BehaviorSubject)
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState.stream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isActive = state != null &&
            state.processingState != AudioProcessingState.idle &&
            state.processingState != AudioProcessingState.completed;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: isActive
              ? _PlayerBar(screenW: screenW, state: state!)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final double screenW;
  final PlaybackState state;

  const _PlayerBar({required this.screenW, required this.state});

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.playing;

    // Usamos mediaItem del handler (también BehaviorSubject)
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem.stream,
      builder: (context, snap) {
        final item = snap.data;
        final noteDisplay = item?.displaySubtitle ?? item?.title ?? '—';

        return Container(
          key: const ValueKey('mini_player'),
          width: screenW,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A5C), Color(0xFF0D2040)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Icono animado de nota
                  _PulsingNoteIcon(isPlaying: isPlaying),

                  const SizedBox(width: 12),

                  // Nombre de la nota
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pad activo',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          noteDisplay,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón Pausar / Reanudar
                  _ControlBtn(
                    icon: isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFF4FC3F7),
                    size: 28,
                    onTap: () {
                      if (isPlaying) {
                        audioHandler.pause();
                      } else {
                        audioHandler.play();
                      }
                    },
                  ),

                  const SizedBox(width: 8),

                  // Botón Parar
                  _ControlBtn(
                    icon: Icons.stop_rounded,
                    color: Colors.redAccent,
                    size: 26,
                    onTap: () => audioHandler.stop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressBar(duration: item?.duration ?? const Duration(minutes: 10)),
            ],
          ),
        );
      },
    );
  }
}

// ── Barra de progreso real con tiempos ──────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final Duration duration;

  const _ProgressBar({required this.duration});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audioHandler.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.08),
                color: const Color(0xFF4FC3F7),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Icono pulsante ──────────────────────────────────────────────────────────
class _PulsingNoteIcon extends StatefulWidget {
  final bool isPlaying;
  const _PulsingNoteIcon({required this.isPlaying});

  @override
  State<_PulsingNoteIcon> createState() => _PulsingNoteIconState();
}

class _PulsingNoteIconState extends State<_PulsingNoteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingNoteIcon old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPlaying) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: widget.isPlaying ? _scale.value : 1.0,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
            ),
            boxShadow: [
              if (widget.isPlaying)
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Botón de control con feedback táctil ────────────────────────────────────
class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _ctrl.value,
          child: child,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.12),
            border:
                Border.all(color: widget.color.withOpacity(0.4), width: 1),
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}
