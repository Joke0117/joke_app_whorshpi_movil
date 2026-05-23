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

  void _handlePress() {
    if (isActive) {
      widget.onNoteChanged('');
      try { audioHandler.stopNote(); } catch(e) { print(e); }
    } else {
      widget.onNoteChanged(widget.note);
      try { audioHandler.playNote('assets/sounds/${widget.note}.mp3'); } catch(e) { print(e); }
    }
  }

  String _getDisplayNote(String rawNote) {
    switch (rawNote) {
      case 'Csharp': return 'Db';
      case 'Csharpm': return 'Dbm';
      case 'Dsharp': return 'Eb';
      case 'Dsharpm': return 'Ebm';
      case 'Fsharp': return 'Gb';
      case 'Fsharpm': return 'Gbm';
      case 'Gsharp': return 'Ab';
      case 'Gsharpm': return 'Abm';
      case 'Asharp': return 'Bb';
      case 'Asharpm': return 'Bbm';
      default: return rawNote.replaceAll('sharp', '#');
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteText = _getDisplayNote(widget.note);
    final screenW = MediaQuery.of(context).size.width;
    // Tamaño de fuente adaptativo: 18–22px según ancho de pantalla
    final fontSize = (screenW * 0.048).clamp(15.0, 22.0);

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
                  color: isActive ? const Color(0xFF4FC3F7) : Colors.white.withOpacity(0.15),
                  width: isActive ? 1.5 : 1,
                ),
                color: isActive
                    ? const Color(0xFF4FC3F7).withOpacity(0.2) // Cristal celeste al estar activo
                    : Colors.white.withOpacity(0.04), // Transparente inactivo
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    noteText,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: isActive ? const Color(0xFF4FC3F7) : Colors.white70,
                    ),
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
