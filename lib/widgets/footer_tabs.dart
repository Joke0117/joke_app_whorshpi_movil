import 'package:flutter/material.dart';
import '../theme/colors.dart';

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
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    // Altura del footer adaptativa: ~10–11% de la pantalla, mín 70, máx 90
    final footerH = (screenH * 0.105).clamp(70.0, 90.0);
    // Padding horizontal adaptativo
    final padH = screenW * 0.025;
    // Tamaño de fuente adaptativo
    final fontSize = (screenW * 0.032).clamp(10.0, 14.0);
    // Tamaño de icono adaptativo
    final iconSize = (screenW * 0.058).clamp(20.0, 26.0);

    return Container(
      height: footerH,
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: padH),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            cardGradientStart,
            cardGradientMiddle,
            cardGradientEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tabButton(
            label: 'Mayores',
            index: 0,
            icon: Icons.music_note,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          _tabButton(
            label: 'Menores',
            index: 1,
            icon: Icons.headphones,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          _tabButton(
            label: 'Info',
            index: 2,
            icon: Icons.info_outline,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required int index,
    required IconData icon,
    required double fontSize,
    required double iconSize,
  }) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => onTabSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeButtonGradientStart.withOpacity(0.85)
                  : const Color(0xFF101928),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeButtonGradientEnd : buttonBorderColor,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeButtonGradientEnd.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? textColor : accentTextColor,
                  size: iconSize,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? textColor : accentTextColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
