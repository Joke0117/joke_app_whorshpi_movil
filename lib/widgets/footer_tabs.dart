import 'package:flutter/material.dart';

class FooterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FooterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      // Fondo transparente — el contenido de la app se ve detrás
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPad > 0 ? bottomPad + 8 : 16,
        top: 8,
      ),
      child: Container(
        // Píldora flotante semitransparente, igual que Instagram
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          // Fondo oscuro semitransparente con el mismo tono de los botones del pad
          color: const Color(0xFF091428).withOpacity(0.82),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.06),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(
              index: 0,
              iconSelected: Icons.library_music,
              iconUnselected: Icons.library_music_outlined,
            ),
            _buildIcon(
              index: 1,
              iconSelected: Icons.headphones,
              iconUnselected: Icons.headphones_outlined,
            ),
            _buildIcon(
              index: 2,
              iconSelected: Icons.queue_music,
              iconUnselected: Icons.queue_music_rounded,
            ),
            _buildIcon(
              index: 3,
              iconSelected: Icons.info,
              iconUnselected: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon({
    required int index,
    required IconData iconSelected,
    required IconData iconUnselected,
  }) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          // El ícono activo tiene un fondo más claro, igual que los botones del pad
          color: isSelected
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isSelected ? iconSelected : iconUnselected,
          color: isSelected ? Colors.white : Colors.white38,
          size: 26,
        ),
      ),
    );
  }
}
