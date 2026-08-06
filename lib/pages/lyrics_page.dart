import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';

class LyricsPage extends StatefulWidget {
  final Song song;
  const LyricsPage({super.key, required this.song});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage>
    with SingleTickerProviderStateMixin {
  late final List<LyricBlock> _blocks;
  int _activeIndex = 0;
  late final PageController _pageController;

  // ── Auto-avance ──────────────────────────────────────────────────────────
  bool _autoPlay = false;
  int _secondsPerSection = 24; // 8 compases × 4/4 a ~75 BPM
  Timer? _autoTimer;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _blocks = widget.song.parsedBlocks;
    _pageController = PageController();
    _progressCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _progressCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Navegación ───────────────────────────────────────────────────────────
  void _goTo(int index) {
    if (index < 0 || index >= _blocks.length) {
      _stopAuto();
      return;
    }
    setState(() => _activeIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Auto-play ────────────────────────────────────────────────────────────
  void _toggleAuto() {
    if (_autoPlay) {
      _stopAuto();
    } else {
      _startAuto();
    }
  }

  void _startAuto() {
    setState(() => _autoPlay = true);
    _launchCycle();
  }

  void _launchCycle() {
    _autoTimer?.cancel();
    // Animación de la barra de cuenta regresiva
    _progressCtrl.value = 0;
    _progressCtrl.animateTo(
      1.0,
      duration: Duration(seconds: _secondsPerSection),
      curve: Curves.linear,
    );
    // Timer de avance
    _autoTimer = Timer(Duration(seconds: _secondsPerSection), () {
      if (!mounted) return;
      if (_activeIndex < _blocks.length - 1) {
        _goTo(_activeIndex + 1);
        _launchCycle();
      } else {
        _stopAuto();
      }
    });
  }

  void _stopAuto() {
    _autoTimer?.cancel();
    _progressCtrl.stop();
    _progressCtrl.value = 0;
    if (mounted) setState(() => _autoPlay = false);
  }

  // Al avanzar/retroceder manualmente durante auto, reinicia el ciclo
  void _manualGoTo(int index) {
    _goTo(index);
    if (_autoPlay) _launchCycle();
  }

  // ── Cambio de velocidad ──────────────────────────────────────────────────
  void _showSpeedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Segundos por sección',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '4/4 a 75 BPM — 8 compases = 24s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              // Valor actual
              Text(
                '${_secondsPerSection}s',
                style: const TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF4FC3F7),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  thumbColor: const Color(0xFF4FC3F7),
                  overlayColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _secondsPerSection.toDouble(),
                  min: 8,
                  max: 60,
                  divisions: 26,
                  onChanged: (v) {
                    setLocal(() {});
                    setState(() => _secondsPerSection = v.round());
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('8s  (4 comp.)',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  Text('60s  (lento)',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 20),
              // Botón aplicar
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (_autoPlay) _launchCycle(); // reinicia con nuevo tiempo
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF4FC3F7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // Overlay semitransparente sobre el fondo del pad
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF040C1A).withOpacity(0.6),
                  const Color(0xFF0A1F44).withOpacity(0.5),
                  const Color(0xFF0D2B60).withOpacity(0.55),
                  const Color(0xFF091428).withOpacity(0.6),
                ],
              ),
            ),
          ),

          // ── Páginas de letra ──────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _blocks.length,
            onPageChanged: (i) {
              setState(() => _activeIndex = i);
              if (_autoPlay) _launchCycle();
            },
            itemBuilder: (context, index) => _LyricSlide(
              block: _blocks[index],
              isActive: index == _activeIndex,
            ),
          ),

          // ── Header ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: mq.padding.top + 8,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF040C1A).withOpacity(0.95),
                    const Color(0xFF040C1A).withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4FC3F7).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF4FC3F7),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.song.artist.isNotEmpty)
                          Text(
                            widget.song.artist,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.song.isMinor
                          ? const Color(0xFF3D1F7A).withOpacity(0.5)
                          : const Color(0xFF0D2B60).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.song.isMinor
                            ? const Color(0xFF9C6FE4)
                            : const Color(0xFF4FC3F7),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      widget.song.keyDisplayName,
                      style: TextStyle(
                        color: widget.song.isMinor
                            ? const Color(0xFFB39DDB)
                            : const Color(0xFF4FC3F7),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer: controles ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: mq.padding.bottom + 16,
                top: 28,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF040C1A).withOpacity(0.95),
                    const Color(0xFF040C1A).withOpacity(0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra de cuenta regresiva (solo visible en auto)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _autoPlay
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _progressCtrl,
                                  builder: (_, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _progressCtrl.value,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.08),
                                      color: const Color(0xFF4FC3F7),
                                      minHeight: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                AnimatedBuilder(
                                  animation: _progressCtrl,
                                  builder: (_, __) {
                                    final remaining = ((_secondsPerSection *
                                                (1 - _progressCtrl.value)))
                                            .round();
                                    return Text(
                                      'Siguiente en ${remaining}s',
                                      style: TextStyle(
                                        color: const Color(0xFF4FC3F7)
                                            .withOpacity(0.6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Indicadores de puntos
                  if (_blocks.length > 1)
                    _DotIndicator(
                        count: _blocks.length, activeIndex: _activeIndex),
                  const SizedBox(height: 16),

                  // Controles: anterior | ▶ auto | siguiente  +  ⚙ velocidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Anterior
                      _NavButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        enabled: _activeIndex > 0,
                        onTap: () => _manualGoTo(_activeIndex - 1),
                      ),

                      // Botón auto + velocidad
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón velocidad
                          GestureDetector(
                            onTap: _showSpeedSheet,
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4FC3F7).withOpacity(0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      const Color(0xFF4FC3F7).withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.speed_rounded,
                                color: Color(0xFF4FC3F7),
                                size: 17,
                              ),
                            ),
                          ),

                          // Botón play/pause auto
                          GestureDetector(
                            onTap: _toggleAuto,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _autoPlay
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1565C0),
                                          Color(0xFF4FC3F7)
                                        ],
                                      )
                                    : null,
                                color: _autoPlay
                                    ? null
                                    : const Color(0xFF4FC3F7).withOpacity(0.1),
                                border: Border.all(
                                  color: const Color(0xFF4FC3F7)
                                      .withOpacity(_autoPlay ? 0 : 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: _autoPlay
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4FC3F7)
                                              .withOpacity(0.4),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                _autoPlay
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Siguiente
                      _NavButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        enabled: _activeIndex < _blocks.length - 1,
                        onTap: () => _manualGoTo(_activeIndex + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide de letra ─────────────────────────────────────────────────────────
class _LyricSlide extends StatelessWidget {
  final LyricBlock block;
  final bool isActive;
  const _LyricSlide({required this.block, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isActive ? 1.0 : 0.25,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: mq.size.height * 0.18,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (block.section != null && !block.isInstruction) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  block.section!,
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (block.isInstruction)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A2800).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        block.content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                block.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white38,
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Indicadores de puntos ──────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _DotIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const maxDots = 9;
    final visibleCount = count.clamp(0, maxDots);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visibleCount, (i) {
        final isActive = i == activeIndex.clamp(0, maxDots - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4FC3F7)
                : const Color(0xFF4FC3F7).withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Botones anterior/siguiente ─────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.15,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.2),
            ),
          ),
          child: Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
        ),
      ),
    );
  }
}
