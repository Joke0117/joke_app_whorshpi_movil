import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/colors.dart';

class PadButton extends StatefulWidget {
  final String note;
  final String currentNote;
  final Function(String) onNoteChanged;

  const PadButton({
    super.key,
    required this.note,
    required this.currentNote,
    required this.onNoteChanged,
  });

  @override
  State<PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<PadButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  bool get isActive => widget.note == widget.currentNote;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (isActive) {
      await audioHandler.stopNote();
      widget.onNoteChanged('');
    } else {
      await audioHandler.playNote('assets/sounds/${widget.note}.mp3');
      widget.onNoteChanged(widget.note);
    }
  }

  String _getDisplayNote(String rawNote) {
    return rawNote.replaceAll('sharp', '#');
  }

  @override
  Widget build(BuildContext context) {
    final noteText = _getDisplayNote(widget.note);

    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeButtonGradientStart.withOpacity(0.6),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(0.7),
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderAccentColor,
                  width: 1,
                ),
                color: isActive
                    ? activeButtonGradientStart.withOpacity(0.7)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  noteText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}