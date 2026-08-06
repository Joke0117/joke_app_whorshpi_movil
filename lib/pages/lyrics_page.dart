import 'package:flutter/material.dart';
import '../models/song.dart';

class LyricsPage extends StatefulWidget {
  final Song song;
  const LyricsPage({super.key, required this.song});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late final List<LyricBlock> _blocks;
  int _activeIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _blocks = widget.song.parsedBlocks;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _blocks.length) return;
    setState(() => _activeIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Mismo fondo degradado de la app ──────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF040C1A),
                  Color(0xFF0A1F44),
                  Color(0xFF0D2B60),
                  Color(0xFF091428),
                ],
              ),
            ),
          ),

          // ── Páginas de letra ─────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _blocks.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
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
                  // Botón cerrar
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
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.song.artist.isNotEmpty)
                          Text(
                            widget.song.artist,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Chip tonalidad — mismo estilo que los PadButtons
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
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
                      boxShadow: [
                        BoxShadow(
                          color: (widget.song.isMinor
                                  ? const Color(0xFF9C6FE4)
                                  : const Color(0xFF4FC3F7))
                              .withOpacity(0.25),
                          blurRadius: 8,
                        ),
                      ],
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

          // ── Footer: indicadores + navegación ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: mq.padding.bottom + 16,
                top: 28,
                left: 28,
                right: 28,
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
                  if (_blocks.length > 1)
                    _DotIndicator(
                        count: _blocks.length, activeIndex: _activeIndex),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        enabled: _activeIndex > 0,
                        onTap: () => _goTo(_activeIndex - 1),
                      ),
                      Text(
                        '${_activeIndex + 1} / ${_blocks.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                      _NavButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        enabled: _activeIndex < _blocks.length - 1,
                        onTap: () => _goTo(_activeIndex + 1),
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

// ── Slide de letra ────────────────────────────────────────────────────────
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
            // Etiqueta de sección
            if (block.section != null && !block.isInstruction) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

            // Instrucción de ejecución
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
              // Letra — misma fuente y estilo blanco de la app
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

// ── Indicadores tipo Spotify ──────────────────────────────────────────────
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

// ── Botones anterior/siguiente ────────────────────────────────────────────
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
