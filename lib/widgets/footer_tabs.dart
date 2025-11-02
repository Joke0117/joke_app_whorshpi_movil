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
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth / 4;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C5364),
            Color(0xFF203A43),
            Color(0xFF0A1F44),
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
          _tabButton('Mayores', 0, icon: Icons.music_note, width: buttonWidth),
          _tabButton('Menores', 1, icon: Icons.headphones, width: buttonWidth),
          _tabButton('Información', 2, icon: Icons.music_video, width: buttonWidth),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, {required IconData icon, required double width}) {
    final bool isSelected = selectedIndex == index;

    return SizedBox(
      width: width,
      height: 80,
      child: OutlinedButton(
        onPressed: () => onTabSelected(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? activeButtonGradientStart : Color(0xFF101928),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          side: BorderSide(color: isSelected ? activeButtonGradientEnd : buttonBorderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? textColor : accentTextColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? textColor : accentTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

