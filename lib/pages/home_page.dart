import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/pad_button.dart';
import '../widgets/footer_tabs.dart';
import '../widgets/developer_info.dart';
import '../widgets/mini_player.dart';
import '../widgets/audio_visualizer.dart';
import '../theme/colors.dart';
import '../widgets/worship_particles.dart';
import 'profile_page.dart';

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

  // Datos del usuario logueado
  int? _userId;
  String _username = '';
  String? _userPhoto;

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
    _requestPermissions();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadUser();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userId = prefs.getInt('logged_user_id');
      _username = prefs.getString('logged_username') ?? '';
      _userPhoto = prefs.getString('logged_user_photo');
    });
  }

  void _openProfile() {
    if (_userId == null) return;
    Navigator.of(context)
        .push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => ProfilePage(
            userId: _userId!,
            username: _username,
            photoPath: _userPhoto,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ))
        .then((_) => _loadUser());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = currentTab == 'developer';
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;

    // Tamaños adaptativos
    final navbarFontSize = screenW * 0.065;
    final navbarPadV = screenH * 0.016;
    final avatarSize = screenW * 0.09;

    return Scaffold(
      body: Stack(
        children: [
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

          WorshipParticles(isMinor: currentTab == 'menores'),

          // Eliminado Visualizador de audio de fondo (ondas animadas) a petición del usuario.
          SafeArea(
            child: Column(
              children: [
                // ── HEADER PROFESIONAL ─────────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenH * 0.02,
                    horizontal: screenW * 0.05,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Textos de Cabecera
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pad Worship',
                            style: TextStyle(
                              fontSize: screenW * 0.04,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentNoteTitle,
                            style: TextStyle(
                              fontSize: screenW * 0.08,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      
                      // Avatar perfil
                      GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          width: screenW * 0.12,
                          height: screenW * 0.12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4FC3F7),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4FC3F7).withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _userPhoto != null
                                ? Image.file(
                                    File(_userPhoto!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person, color: Colors.white70),
                                  )
                                : const Icon(Icons.person, color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // (Barra de progreso movida al MiniPlayer)

                // ── Mini player flotante ───────────────────────────────────
                const MiniPlayer(),

                // ── Contenido principal ────────────────────────────────────
                if (isDeveloper)
                  const Expanded(child: DeveloperInfo())
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
                        final rowCount = (notes.length / crossAxisCount).ceil();
                        final availH = constraints.maxHeight;
                        const spacing = 5.0;
                        const padV = 6.0;

                        final cellH = (availH - spacing * (rowCount - 1) - 2 * padV) / rowCount;
                        final cellW = constraints.maxWidth / crossAxisCount;
                        // Relación de aspecto dinámica para que ocupen exactamente la pantalla sin desbordarse
                        double aspectRatio = cellW / cellH;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: padV),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                                horizontal: screenW * 0.04),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: aspectRatio,
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

                const SizedBox(height: 8),

                // ── Footer tabs ────────────────────────────────────────────
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
