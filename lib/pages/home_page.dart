import 'package:flutter/material.dart';
import '../widgets/pad_button.dart';
import '../widgets/footer_tabs.dart';
import '../widgets/developer_info.dart';
import '../theme/colors.dart';
import '../widgets/worship_particles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String currentTab = 'mayores';
  String currentNote = '';
  String currentNoteTitle = 'Pad Worship';
  bool isPlaying = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  List<String> get notes {
    return currentTab == 'mayores'
        ? ['C', 'Csharp', 'D', 'Dsharp', 'E', 'F', 'Fsharp', 'G', 'Gsharp', 'A', 'Asharp', 'B']
        : ['Cm', 'Csharpm', 'Dm', 'Dsharpm', 'Em', 'Fm', 'Fsharpm', 'Gm', 'Gsharpm', 'Am', 'Asharpm', 'Bm'];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = currentTab == 'developer';

    return Scaffold(
      body: Stack(
        children: [
          // Fondo general
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1F44),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),

          WorshipParticles(isMinor: currentTab == 'menores'),

          SafeArea(
            child: Column(
              children: [
                // NAVBAR con fondo animado y luz fundida
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final gradient = const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A1F44),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),
                      ],
                    );

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        boxShadow: [
                          BoxShadow(
                            color: navbarFooterGradientMiddle.withOpacity(0.25 * _animation.value),
                            blurRadius: 25,
                            spreadRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Texto grande de fondo con luz tenue
                          Opacity(
                            opacity: 0.18 * _animation.value,
                            child: Text(
                              currentNoteTitle,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.25),
                                shadows: [
                                  Shadow(
                                    color: Colors.blueGrey.withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Título principal con luz sutil animada
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.85),
                                  Colors.lightBlueAccent.withOpacity(0.4),
                                  Colors.white.withOpacity(0.85),
                                ],
                                stops: [
                                  (_controller.value - 0.2).clamp(0.0, 1.0),
                                  _controller.value.clamp(0.0, 1.0),
                                  (_controller.value + 0.2).clamp(0.0, 1.0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              currentNoteTitle,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(1, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                if (isPlaying)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: activeButtonGradientEnd,
                    minHeight: 3,
                  ),

                const SizedBox(height: 34),

                if (isDeveloper)
                  const Expanded(child: DeveloperInfo())
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final crossAxisCount = isMobile ? 2 : 3;
                        final rowCount = (notes.length / crossAxisCount).ceil();

                        final availableHeight = constraints.maxHeight;
                        final spacing = 5.0;
                        final desiredPadding = 5.0;

                        final cellHeight = (availableHeight - spacing * (rowCount - 1) - 2 * desiredPadding) / rowCount;
                        final cellWidth = constraints.maxWidth / crossAxisCount;

                        double aspectRatio = cellWidth / cellHeight;
                        if (aspectRatio < 0.75) aspectRatio = 0.75;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: aspectRatio * 0.92,
                            children: notes.map((note) {
                              return PadButton(
                                key: ValueKey('${currentTab}_$note'),
                                note: note,
                                currentNote: currentNote,
                                onNoteChanged: (newNote) {
                                  setState(() {
                                    if (currentNote != newNote) {
                                      currentNote = newNote;
                                      currentNoteTitle = newNote.isEmpty
                                          ? 'Pad Worship'
                                          : newNote.replaceAll('sharp', '#');
                                      isPlaying = newNote.isNotEmpty;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                FooterTabs(
                  selectedIndex: _getTabIndex(),
                  onTabSelected: (index) {
                    setState(() {
                      currentTab = _getTabFromIndex(index);
                      if (currentNote.isEmpty) {
                        currentNoteTitle = 'Pad Worship';
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTabIndex() {
    switch (currentTab) {
      case 'mayores':
        return 0;
      case 'menores':
        return 1;
      case 'developer':
        return 2;
      default:
        return 0;
    }
  }

  String _getTabFromIndex(int index) {
    switch (index) {
      case 0:
        return 'mayores';
      case 1:
        return 'menores';
      case 2:
        return 'developer';
      default:
        return 'mayores';
    }
  }
}

