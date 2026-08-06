import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import 'song_editor_page.dart';
import 'lyrics_page.dart';

/// Callback para que SetlistPage le diga a HomePage qué pad activar.
typedef OnActivatePad = void Function(String note, bool isMinor);

class SetlistPage extends StatefulWidget {
  final OnActivatePad onActivatePad;

  const SetlistPage({super.key, required this.onActivatePad});

  @override
  State<SetlistPage> createState() => _SetlistPageState();
}

class _SetlistPageState extends State<SetlistPage> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await SongService.getAll();
    if (mounted) setState(() { _songs = songs; _loading = false; });
  }

  Future<void> _openEditor({Song? song}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SongEditorPage(song: song)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Song song) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F3C),
        title: const Text('Eliminar canción',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${song.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await SongService.delete(song.id!);
      _load();
    }
  }

  void _openLyrics(Song song) {
    // Activa el pad de la tonalidad de la canción
    widget.onActivatePad(song.key, song.isMinor);

    // Abre la pantalla de letra
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LyricsPage(song: song),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040C1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF040C1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Setlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4FC3F7), size: 28),
            onPressed: () => _openEditor(),
            tooltip: 'Agregar canción',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
          : _songs.isEmpty
              ? _EmptyState(onAdd: () => _openEditor())
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 100, top: 8),
                  itemCount: _songs.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final list = List<Song>.from(_songs);
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);
                    setState(() => _songs = list);
                    SongService.reorder(list);
                  },
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return _SongTile(
                      key: ValueKey(song.id),
                      song: song,
                      onTap: () => _openLyrics(song),
                      onEdit: () => _openEditor(song: song),
                      onDelete: () => _delete(song),
                    );
                  },
                ),
    );
  }
}

// ── Tarjeta de canción ────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${song.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 26),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E3A5F)),
          ),
          child: Row(
            children: [
              // Drag handle
              const Icon(
                Icons.drag_handle_rounded,
                color: Colors.white24,
                size: 22,
              ),
              const SizedBox(width: 12),

              // Nombre y artista
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (song.artist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chip de tonalidad
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: song.isMinor
                      ? const Color(0xFF6C3EC4).withOpacity(0.2)
                      : const Color(0xFF1565C0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: song.isMinor
                        ? const Color(0xFF6C3EC4)
                        : const Color(0xFF1565C0),
                    width: 1,
                  ),
                ),
                child: Text(
                  song.keyDisplayName,
                  style: TextStyle(
                    color: song.isMinor
                        ? const Color(0xFFB39DDB)
                        : const Color(0xFF4FC3F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón editar
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white30,
                    size: 18,
                  ),
                ),
              ),

              // Flecha para abrir letra
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 72,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin canciones todavía',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar la primera\ncanción de tu setlist',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Agregar canción',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
