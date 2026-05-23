import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepScreenOn = prefs.getBool('keep_screen_on') ?? false;
    });
    _applyWakelock(_keepScreenOn);
  }

  Future<void> _toggleScreenOn(bool value) async {
    setState(() {
      _keepScreenOn = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_screen_on', value);
    _applyWakelock(value);
  }

  void _applyWakelock(bool enable) {
    if (enable) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040C1A), Color(0xFF0D2B60)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Sección de Pantalla
              const Text(
                'PANTALLA Y ENERGÍA',
                style: TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: SwitchListTile(
                  value: _keepScreenOn,
                  onChanged: _toggleScreenOn,
                  activeColor: const Color(0xFF4FC3F7),
                  title: const Text('Mantener pantalla encendida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Evita que el teléfono se bloquee mientras tocas en vivo.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: Color(0xFF4FC3F7)),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Sección Acerca de
              const Text(
                'ACERCA DE',
                style: TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB39DDB).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: Color(0xFFB39DDB)),
                  ),
                  title: const Text('Versión de la App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
