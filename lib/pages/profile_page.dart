import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String username;
  final String? photoPath;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.username,
    this.photoPath,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late String? _currentPhotoPath;
  late String _currentUsername;
  bool _isUpdating = false;

  late AnimationController _anim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _currentPhotoPath = widget.photoPath;
    _currentUsername = widget.username;

    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cambiar foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: Color(0xFF4FC3F7)),
                title: const Text('Cámara',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF4FC3F7)),
                title: const Text('Galería',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null || !mounted) return;

      // Copiar a directorio permanente (el temporal se borra en días)
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${photosDir.path}/profile_$timestamp.jpg';
      await File(picked.path).copy(permanentPath);

      if (!mounted) return;
      setState(() {
        _currentPhotoPath = permanentPath;
        _isUpdating = true;
      });

      await DatabaseService.instance.updateUserPhoto(
        userId: widget.userId,
        photoPath: permanentPath,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user_photo', permanentPath);

      if (!mounted) return;
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Foto actualizada'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Deseas cerrar tu sesión?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_user_id');
      await prefs.remove('logged_username');
      await prefs.remove('logged_user_photo');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D1B3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Cambiar contrase\u00f1a',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentCtrl,
                      obscureText: obscureCurrent,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contrase\u00f1a actual',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.55)),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF4FC3F7), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF4FC3F7), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nueva contrase\u00f1a',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.55)),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF4FC3F7), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(
                              () => obscureNew = !obscureNew),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF4FC3F7), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contrase\u00f1a',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.55)),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF4FC3F7), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF4FC3F7), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    if (newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Completa todos los campos'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('M\u00ednimo 6 caracteres'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (newCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Las contrase\u00f1as no coinciden'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Verificar contrase\u00f1a actual
                    final user = await DatabaseService.instance.loginUser(
                      username: _currentUsername,
                      password: currentCtrl.text,
                    );
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Contrase\u00f1a actual incorrecta'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Actualizar
                    final ok = await DatabaseService.instance.updatePassword(
                      _currentUsername,
                      newCtrl.text,
                    );
                    if (ok) {
                      Navigator.pop(ctx, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Error al cambiar contrase\u00f1a'),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Cambiar',
                      style: TextStyle(color: Color(0xFF4FC3F7))),
                ),
              ],
            );
          },
        );
      },
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contrase\u00f1a cambiada con \u00e9xito'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // AppBar manual
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Mi Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          );
                        },
                        tooltip: 'Ajustes',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout,
                            color: Colors.redAccent),
                        onPressed: _logout,
                        tooltip: 'Cerrar sesión',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: Column(
                      children: [
                        // Avatar grande
                        GestureDetector(
                          onTap: _changePhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0A1F44),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4FC3F7)
                                          .withOpacity(0.45),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.5),
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _isUpdating
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF4FC3F7),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : _currentPhotoPath != null
                                          ? Image.file(
                                              File(_currentPhotoPath!),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      const Icon(
                                                Icons.person,
                                                size: 65,
                                                color: Colors.white54,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 65,
                                              color: Colors.white54,
                                            ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4FC3F7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF040C1A),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4FC3F7)
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Nombre de usuario
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFF4FC3F7),
                                Colors.white,
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            _currentUsername,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Músico de Worship',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.45),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Tarjeta de info
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _infoRow(
                                  Icons.person_outline, 'Usuario',
                                  _currentUsername),
                              const Divider(color: Colors.white12, height: 24),
                              _infoRow(
                                  Icons.security, 'Contraseña', '••••••••'),
                              const Divider(color: Colors.white12, height: 24),
                              _infoRow(Icons.photo_camera_outlined,
                                  'Foto de perfil',
                                  _currentPhotoPath != null
                                      ? 'Configurada ✓'
                                      : 'No configurada'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botón cambiar foto
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF4FC3F7), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _changePhoto,
                            icon: const Icon(Icons.camera_alt,
                                color: Color(0xFF4FC3F7)),
                            label: const Text(
                              'Cambiar foto de perfil',
                              style: TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Botón cambiar contraseña
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: const Color(0xFFB39DDB).withOpacity(0.6),
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _showChangePasswordDialog,
                            icon: const Icon(Icons.lock_outline,
                                color: Color(0xFFB39DDB)),
                            label: const Text(
                              'Cambiar contrase\u00f1a',
                              style: TextStyle(
                                color: Color(0xFFB39DDB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Botón cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.6),
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _logout,
                            icon: const Icon(Icons.logout,
                                color: Colors.redAccent),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
