import 'package:flutter/material.dart';
import '../models/song.dart';

/// Pantalla de letra estilo Spotify:
/// - Fondo negro total
/// - Sección activa resaltada en blanco brillante
/// - Resto del contenido atenuado
/// - Instrucciones en color ámbar resaltado
/// - Navegación con swipe o flechas
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
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PÁGINAS DE LETRA ───────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _blocks.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            itemBuilder: (context, index) {
              return _LyricSlide(
                block: _blocks[index],
                isActive: index == _activeIndex,
              );
            },
          ),

          // ── HEADER ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: mq.padding.top + 8,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Botón cerrar
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.song.artist.isNotEmpty)
                          Text(
                            widget.song.artist,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Chip de tonalidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.song.isMinor
                          ? const Color(0xFF6C3EC4)
                          : const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.song.keyDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── FOOTER: navegación + indicadores ─────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: mq.padding.bottom + 16,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicadores de puntos (máx 10 visibles)
                  if (_blocks.length > 1)
                    _DotIndicator(
                      count: _blocks.length,
                      activeIndex: _activeIndex,
                    ),
                  const SizedBox(height: 16),
                  // Controles anterior / siguiente
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
                          color: Colors.white.withOpacity(0.4),
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

// ── Slide de letra individual ─────────────────────────────────────────────
class _LyricSlide extends StatelessWidget {
  final LyricBlock block;
  final bool isActive;

  const _LyricSlide({required this.block, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isActive ? 1.0 : 0.3,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: mq.size.height * 0.18,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Etiqueta de sección
            if (block.section != null && !block.isInstruction) ...[
              Text(
                block.section!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Instrucción de ejecución
            if (block.isInstruction)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFFF9800),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        block.content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Letra normal
              Text(
                block.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.65,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Indicadores de puntos estilo Spotify ─────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    // Máximo 9 puntos visibles con un punto de overflow
    const maxDots = 9;
    final visibleCount = count.clamp(0, maxDots);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visibleCount, (i) {
        final isActive = i == activeIndex.clamp(0, maxDots - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Botón de navegación ───────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.2,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
