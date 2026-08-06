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
    // Al estilo Instagram: una barra inferior plana, fondo oscuro/negro, solo íconos.
    return Container(
      color: const Color(0xFF000000), // Fondo negro tipo Instagram
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom > 0 
            ? MediaQuery.of(context).padding.bottom 
            : 12,
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
            iconSelected: Icons.info,
            iconUnselected: Icons.info_outline,
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Icon(
          isSelected ? iconSelected : iconUnselected,
          color: isSelected ? Colors.white : Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}

