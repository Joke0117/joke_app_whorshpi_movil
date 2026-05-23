import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_handler.dart';
import 'pages/splash_screen.dart';

late AudioHandlerService audioHandler;

/// Ruta al archivo de imagen de carátula en disco (accesible por notificaciones nativas).
String? audioArtworkPath;

/// Copia el asset de imagen al directorio de documentos de la app para que
/// las notificaciones nativas del SO puedan acceder a él como URI de archivo.
Future<void> _copyArtworkToDisk() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pad_worship_art.png');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/images/icon_app.png');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    audioArtworkPath = file.path;
  } catch (e) {
    debugPrint('No se pudo copiar artwork al disco: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura errores globales de Flutter sin cerrar la app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // 🖼️ Copiar artwork al disco para que las notificaciones nativas puedan leerlo
  await _copyArtworkToDisk();

  // 🔒 Forzar solo orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🎨 Estilo de la barra de sistema (transparente)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF040C1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 🎵 Configurar sesión de audio para reproducción continua en segundo plano
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // 🎵 Registrar AudioHandler con audio_service (notificación del sistema)
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioHandlerService(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.joke.padworship.audio',
        androidNotificationChannelName: 'Pad Worship',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    debugPrint('AudioService OK — notificaciones activas');
  } catch (e) {
    debugPrint('AudioService.init falló: $e — sin notificaciones, audio ok');
    audioHandler = AudioHandlerService();
  }

  try {

    // 🎵 Precargar audios
    await audioHandler.preloadNotes([
      'assets/sounds/C.mp3',
      'assets/sounds/Csharp.mp3',
      'assets/sounds/D.mp3',
      'assets/sounds/Dsharp.mp3',
      'assets/sounds/E.mp3',
      'assets/sounds/F.mp3',
      'assets/sounds/Fsharp.mp3',
      'assets/sounds/G.mp3',
      'assets/sounds/Gsharp.mp3',
      'assets/sounds/A.mp3',
      'assets/sounds/Asharp.mp3',
      'assets/sounds/B.mp3',
      'assets/sounds/Cm.mp3',
      'assets/sounds/Csharpm.mp3',
      'assets/sounds/Dm.mp3',
      'assets/sounds/Dsharpm.mp3',
      'assets/sounds/Em.mp3',
      'assets/sounds/Fm.mp3',
      'assets/sounds/Fsharpm.mp3',
      'assets/sounds/Gm.mp3',
      'assets/sounds/Gsharpm.mp3',
      'assets/sounds/Am.mp3',
      'assets/sounds/Asharpm.mp3',
      'assets/sounds/Bm.mp3',
    ]);
  } catch (e) {
    // Si el audio falla, la app igual arranca (sin audio hasta que funcione)
    debugPrint('AudioService init error: $e');
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pad Worship',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF040C1A),
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

