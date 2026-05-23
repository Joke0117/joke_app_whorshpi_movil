import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _photoPath;

  late AnimationController _cardController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
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
                'Seleccionar foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: Color(0xFF4FC3F7)),
                title: const Text('Cámara',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF4FC3F7)),
                title: const Text('Galería',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFrom(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text('Quitar foto',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null) return;

      // Copiar a directorio permanente
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${photosDir.path}/profile_$timestamp.jpg';
      await File(picked.path).copy(permanentPath);

      if (mounted) setState(() => _photoPath = permanentPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo acceder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await DatabaseService.instance.registerUser(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      photoPath: _photoPath,
    );

    if (!mounted) return;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('logged_user_id', user.id!);
      await prefs.setString('logged_username', user.username);
      if (user.photoPath != null) {
        await prefs.setString('logged_user_photo', user.photoPath!);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (_) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'El nombre de usuario ya existe. Elige otro.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          child: AnimatedBuilder(
            animation: _cardController,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, _cardSlide.value),
                child: Opacity(
                  opacity: _cardOpacity.value,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Avatar / foto de perfil
                            Center(
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
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
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFF4FC3F7)
                                              .withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: _photoPath != null
                                            ? Image.file(
                                                File(_photoPath!),
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 55,
                                                color: Colors.white54,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4FC3F7),
                                          shape: BoxShape.circle,
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
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Toca para agregar foto',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Formulario glassmorphism
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _usernameCtrl,
                                      label: 'Usuario *',
                                      icon: Icons.person_outline,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'El usuario es obligatorio';
                                        }
                                        if (v.trim().length < 3) {
                                          return 'Mínimo 3 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _emailCtrl,
                                      label: 'Correo (opcional)',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _passwordCtrl,
                                      label: 'Contraseña *',
                                      icon: Icons.lock_outline,
                                      obscure: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'La contraseña es obligatoria';
                                        }
                                        if (v.length < 6) {
                                          return 'Mínimo 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _confirmCtrl,
                                      label: 'Confirmar contraseña *',
                                      icon: Icons.lock_outline,
                                      obscure: _obscureConfirm,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                      ),
                                      validator: (v) {
                                        if (v != _passwordCtrl.text) {
                                          return 'Las contraseñas no coinciden';
                                        }
                                        return null;
                                      },
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.red
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline,
                                                color: Colors.redAccent,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: _isLoading
                                          ? const Center(
                                              child: SizedBox(
                                                width: 26,
                                                height: 26,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFF4FC3F7),
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                            )
                                          : DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF4FC3F7),
                                                    Color(0xFF1976D2),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                            0xFF4FC3F7)
                                                        .withOpacity(0.35),
                                                    blurRadius: 16,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                ),
                                                onPressed: _register,
                                                child: const Text(
                                                  'CREAR CUENTA',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
        prefixIcon: Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8)),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
