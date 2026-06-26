import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. Import services
import 'package:my_app/pages/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: const Color.fromARGB(255, 0, 0, 0),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

void main() async {
  // Ensures Flutter framework is fully initialized before calling native platform code
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 2. Lock the orientation to standard portrait mode only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomePage(),
    );
  }
}
