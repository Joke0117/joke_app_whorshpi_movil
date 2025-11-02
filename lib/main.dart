import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_handler.dart';
import 'pages/home_page.dart';


late final AudioHandlerService audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar sesión de audio para reproducción continua y en segundo plano
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Inicializar el audio handler y precargar los audios
  audioHandler = AudioHandlerService();
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pad Worship',
      home: const HomePage(),
    );
  }
}