import 'package:flutter/material.dart';

class FooterTabs extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FooterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<FooterTabs> createState() => _FooterTabsState();
}

class _FooterTabsState extends State<FooterTabs> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.selectedIndex,
      viewportFraction: 0.25, // cada tab ocupa 25% del ancho
    );
  }

  @override
  void didUpdateWidget(covariant FooterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const _tabs = [
    (Icons.library_music, Icons.library_music_outlined),
    (Icons.headphones, Icons.headphones_outlined),
    (Icons.queue_music, Icons.queue_music_rounded),
    (Icons.info, Icons.info_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        // más espacio inferior → lo baja un poco respecto al borde
        bottom: bottomPad > 0 ? bottomPad + 14 : 22,
        top: 10,  // un poco más de espacio superior
      ),
      child: Container(
        // Un poco más grueso: vertical padding de 14 en lugar de 10
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // PageView para deslizamiento horizontal + clic
        child: PageView.builder(
          controller: _pageController,
          itemCount: _tabs.length,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) => widget.onTabSelected(index),
          itemBuilder: (context, index) {
            final (iconSelected, iconUnselected) = _tabs[index];
            final bool isSelected = widget.selectedIndex == index;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onTabSelected(index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? iconSelected : iconUnselected,
                    color: isSelected ? Colors.white : Colors.white38,
                    size: 26,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
