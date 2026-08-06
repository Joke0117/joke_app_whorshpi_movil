class Song {
  final int? id;
  final String title;
  final String artist;
  final String key;       // "C", "Dm", "Gsharp", "Gsharpm", etc.
  final bool isMinor;
  final String rawLyrics; // Texto crudo con [Sección] y *instrucciones*
  final int order;

  const Song({
    this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.isMinor,
    required this.rawLyrics,
    this.order = 0,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? key,
    bool? isMinor,
    String? rawLyrics,
    int? order,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      isMinor: isMinor ?? this.isMinor,
      rawLyrics: rawLyrics ?? this.rawLyrics,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'key': key,
        'isMinor': isMinor ? 1 : 0,
        'rawLyrics': rawLyrics,
        'order': order,
      };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id'] as int?,
        title: map['title'] as String,
        artist: map['artist'] as String,
        key: map['key'] as String,
        isMinor: (map['isMinor'] as int) == 1,
        rawLyrics: map['rawLyrics'] as String,
        order: map['order'] as int,
      );

  /// Devuelve el nombre de la tonalidad para mostrar en UI
  String get keyDisplayName {
    final base = key
        .replaceAll('sharp', '#')
        .replaceAll('m', '')
        .replaceAll('#', '♯');
    return isMinor ? '${base}m' : base;
  }

  /// Parsea rawLyrics en bloques: cada bloque tiene un tipo y contenido.
  List<LyricBlock> get parsedBlocks {
    final blocks = <LyricBlock>[];
    final lines = rawLyrics.split('\n');

    String? currentSection;
    final buffer = StringBuffer();

    void flush() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty || currentSection != null) {
        blocks.add(LyricBlock(
          section: currentSection,
          content: text,
        ));
      }
      buffer.clear();
      currentSection = null;
    }

    for (final raw in lines) {
      final line = raw.trim();

      // Encabezado de sección: [Coro], [Verso 1], [Puente], etc.
      if (line.startsWith('[') && line.endsWith(']')) {
        flush();
        currentSection = line.substring(1, line.length - 1).toUpperCase();
        continue;
      }

      // Instrucción: *Sin batería*, *2x*, etc.
      if (line.startsWith('*') && line.endsWith('*') && line.length > 2) {
        // Guarda lo que había antes como un bloque de letra
        final text = buffer.toString().trim();
        if (text.isNotEmpty) {
          blocks.add(LyricBlock(section: currentSection, content: text));
          currentSection = null;
          buffer.clear();
        } else if (currentSection != null) {
          // Sección sin letra todavía, la ponemos como cabecera del instrucción
        }
        blocks.add(LyricBlock(
          section: currentSection,
          content: line.substring(1, line.length - 1),
          isInstruction: true,
        ));
        currentSection = null;
        buffer.clear();
        continue;
      }

      if (line.isEmpty && buffer.isNotEmpty) {
        buffer.write('\n');
      } else if (line.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(line);
      }
    }
    flush();
    return blocks.where((b) => b.content.isNotEmpty || b.section != null).toList();
  }
}

class LyricBlock {
  final String? section;
  final String content;
  final bool isInstruction;

  const LyricBlock({
    this.section,
    required this.content,
    this.isInstruction = false,
  });
}
