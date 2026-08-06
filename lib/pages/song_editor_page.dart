import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../theme/colors.dart';

/// Pantalla para crear o editar una canción.
class SongEditorPage extends StatefulWidget {
  final Song? song; // null = crear nueva

  const SongEditorPage({super.key, this.song});

  @override
  State<SongEditorPage> createState() => _SongEditorPageState();
}

class _SongEditorPageState extends State<SongEditorPage> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();

  String _selectedKey = 'C';
  bool _isMinor = false;

  // Notas en orden cromático
  static const _majorKeys = [
    'C', 'Csharp', 'D', 'Dsharp', 'E',
    'F', 'Fsharp', 'G', 'Gsharp', 'A', 'Asharp', 'B',
  ];

  String _displayKey(String key) =>
      key.replaceAll('sharp', '♯');

  @override
  void initState() {
    super.initState();
    if (widget.song != null) {
      final s = widget.song!;
      _titleCtrl.text = s.title;
      _artistCtrl.text = s.artist;
      _lyricsCtrl.text = s.rawLyrics;
      _selectedKey = s.key.replaceAll('m', '');
      _isMinor = s.isMinor;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _lyricsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la canción')),
      );
      return;
    }

    final keyFull = _isMinor ? '${_selectedKey}m' : _selectedKey;

    final song = Song(
      id: widget.song?.id,
      title: title,
      artist: _artistCtrl.text.trim(),
      key: keyFull,
      isMinor: _isMinor,
      rawLyrics: _lyricsCtrl.text,
      order: widget.song?.order ?? 999,
    );

    if (song.id == null) {
      await SongService.insert(song);
    } else {
      await SongService.update(song);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF040C1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF040C1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.song == null ? 'Nueva canción' : 'Editar canción',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: mq.viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre ─────────────────────────────────────────────
            _label('Nombre de la canción'),
            _field(_titleCtrl, 'Ej: Santo'),
            const SizedBox(height: 20),

            // ── Artista ────────────────────────────────────────────
            _label('Artista / Grupo (opcional)'),
            _field(_artistCtrl, 'Ej: Marcos Witt'),
            const SizedBox(height: 24),

            // ── Tonalidad ──────────────────────────────────────────
            _label('Tonalidad'),
            const SizedBox(height: 10),

            // Mayor / Menor toggle
            Row(
              children: [
                _ModeChip(
                  label: 'Mayor',
                  selected: !_isMinor,
                  onTap: () => setState(() => _isMinor = false),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: 'Menor',
                  selected: _isMinor,
                  onTap: () => setState(() => _isMinor = true),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de notas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _majorKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (_, i) {
                final k = _majorKeys[i];
                final isSelected = _selectedKey == k;
                return GestureDetector(
                  onTap: () => setState(() => _selectedKey = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (_isMinor
                              ? const Color(0xFF6C3EC4)
                              : const Color(0xFF1565C0))
                          : const Color(0xFF0D1F3C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white30
                            : const Color(0xFF1E3A5F),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _displayKey(k),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Letra ──────────────────────────────────────────────
            _label('Letra'),
            const SizedBox(height: 6),

            // Hint de formato
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F3C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFF4FC3F7), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Formato de la letra',
                        style: TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '[Verso 1]\nPegá la letra aquí...\n\n[Coro]\nLa letra del coro...\n\n*Sin batería — suave*\n\n[Puente]\nLetra del puente...',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Campo de letra
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: TextField(
                controller: _lyricsCtrl,
                maxLines: null,
                minLines: 12,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText:
                      '[Verso 1]\nSanto, santo, santo...\n\n[Coro]\n¡Santo es el Señor!',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _field(TextEditingController ctrl, String hint) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white30 : const Color(0xFF1E3A5F),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
