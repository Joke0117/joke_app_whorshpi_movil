import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart'; // Asegúrate de que esta ruta sea correcta

class DeveloperInfo extends StatefulWidget {
  const DeveloperInfo({super.key});

  @override
  State<DeveloperInfo> createState() => _DeveloperInfoState();
}

class _DeveloperInfoState extends State<DeveloperInfo> {
  bool _facebookPressed = false;
  bool _instagramPressed = false;
  bool _isCardPressed1 = false;
  bool _isCardPressed2 = false;

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir $url';
    }
  }

  void _onFacebookTap() {
    setState(() {
      _facebookPressed = true;
      _instagramPressed = false;
    });
    _launchURL('https://www.facebook.com/joseangel.martinezrodelo');
  }

  void _onInstagramTap() {
    setState(() {
      _instagramPressed = true;
      _facebookPressed = false;
    });
    _launchURL('https://www.instagram.com/joke_0117/');
  }

  Widget _card({
    required Widget child,
    required bool isCardPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        transform: Matrix4.translationValues(0, isCardPressed ? -10 : 0, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              cardGradientStart,
              cardGradientMiddle,
              cardGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: isCardPressed ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: activeButtonGradientEnd.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _hoverableSocial({
    required IconData icon,
    required String text,
    required Color activeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            color: isActive ? activeColor : textColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isActive ? activeColor : textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tarjeta: Acerca del Desarrollador
          _card(
            isCardPressed: _isCardPressed1,
            onTapDown: () => setState(() => _isCardPressed1 = true),
            onTapUp: () => setState(() => _isCardPressed1 = false),
            onTapCancel: () => setState(() => _isCardPressed1 = false),
            child: Column(
              children: const [
                Icon(Icons.person, size: 48, color: accentTextColor),
                SizedBox(height: 12),
                Text(
                  'Acerca del Desarrollador',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentTextColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Hola, ¡Bienvenidos! A mi App de Pad Worship.\n\nMe llamo José, desarrollador apasionado por la música y la tecnología.',
                  style: TextStyle(fontSize: 16, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tarjeta: Redes Sociales
          _card(
            isCardPressed: _isCardPressed2,
            onTapDown: () => setState(() => _isCardPressed2 = true),
            onTapUp: () => setState(() => _isCardPressed2 = false),
            onTapCancel: () => setState(() => _isCardPressed2 = false),
            child: Column(
              children: [
                const Text(
                  'Redes Sociales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                _hoverableSocial(
                  icon: FontAwesomeIcons.facebook,
                  text: '@josemartinez',
                  activeColor: activeButtonGradientEnd,
                  isActive: _facebookPressed,
                  onTap: _onFacebookTap,
                ),
                const SizedBox(height: 12),
                _hoverableSocial(
                  icon: FontAwesomeIcons.instagram,
                  text: '@joke_0117',
                  activeColor: activeButtonGradientEnd,
                  isActive: _instagramPressed,
                  onTap: _onInstagramTap,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Texto final tipo marca de agua
          const Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              '© 2025 - Developed by Ing. José Martínez • v1.0.0',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
