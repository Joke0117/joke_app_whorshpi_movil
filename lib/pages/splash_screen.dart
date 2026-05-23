import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controladores de animación ──────────────────────────────────────────
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _fadeOutController;

  // ── Animaciones logo ────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowRadius;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _bgOpacity;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Fondo
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeIn),
    );

    // Logo principal (scale + fade)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Resplandor (glow) pulsante
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowRadius = Tween<double>(begin: 30, end: 90).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Texto slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Fade out final
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // 1. Fondo aparece
    await _bgController.forward();

    // 2. Logo entra con bounce
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();

    // 3. Glow aparece
    await _glowController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Texto sube
    await _textController.forward();

    // 5. Pausa para que el usuario vea el splash
    await Future.delayed(const Duration(milliseconds: 1800));

    // 6. Fade out y navegar
    await _fadeOutController.forward();

    if (!mounted) return;
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('logged_user_id');

    if (!mounted) return;

    if (userId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgController,
        _logoController,
        _glowController,
        _textController,
        _fadeOutController,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeOut,
          child: Opacity(
            opacity: _bgOpacity.value,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.4,
                    colors: [
                      Color(0xFF0D1B3E),
                      Color(0xFF091428),
                      Color(0xFF040C1A),
                      Colors.black,
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Partículas de fondo (estrellas estáticas)
                    ..._buildStarField(),

                    // Contenido central
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glow detrás del logo
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Resplandor exterior
                              Opacity(
                                opacity: _glowOpacity.value * 0.5,
                                child: Container(
                                  width: _glowRadius.value * 2.5,
                                  height: _glowRadius.value * 2.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4FC3F7)
                                            .withOpacity(0.3),
                                        blurRadius: _glowRadius.value,
                                        spreadRadius: _glowRadius.value * 0.5,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFB39DDB)
                                            .withOpacity(0.2),
                                        blurRadius: _glowRadius.value * 1.5,
                                        spreadRadius: _glowRadius.value * 0.3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Logo principal con scale y fade
                              Transform.scale(
                                scale: _logoScale.value,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4FC3F7)
                                              .withOpacity(
                                                  _glowOpacity.value * 0.6),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/icon_app.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF4FC3F7),
                                                  Color(0xFF0A1F44),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.music_note,
                                              size: 80,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // Título con slide up y fade
                          Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Opacity(
                              opacity: _textOpacity.value,
                              child: Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        colors: [
                                          Color(0xFF4FC3F7),
                                          Colors.white,
                                          Color(0xFFB39DDB),
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      'PAD WORSHIP',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'by Jose Martínez',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                      color:
                                          Colors.white.withOpacity(0.55),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStarField() {
    final stars = <Widget>[];
    final positions = [
      [0.05, 0.08], [0.15, 0.15], [0.88, 0.12], [0.92, 0.25],
      [0.03, 0.35], [0.97, 0.40], [0.10, 0.55], [0.85, 0.60],
      [0.20, 0.75], [0.78, 0.80], [0.45, 0.05], [0.60, 0.92],
      [0.30, 0.20], [0.70, 0.18], [0.50, 0.88], [0.08, 0.70],
      [0.93, 0.70], [0.35, 0.90], [0.65, 0.95], [0.25, 0.45],
    ];

    for (int i = 0; i < positions.length; i++) {
      final size = (i % 3 == 0) ? 2.5 : (i % 3 == 1) ? 1.5 : 1.0;
      stars.add(
        Positioned(
          left: positions[i][0] * MediaQuery.of(context).size.width,
          top: positions[i][1] * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: _bgOpacity.value * (0.4 + (i % 4) * 0.15),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: size * 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return stars;
  }
}
