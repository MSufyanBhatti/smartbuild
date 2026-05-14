import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'language_controller.dart';
import 'app_language.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  final appLanguage = AppLanguage();
  await appLanguage.loadLanguage();
  runApp(
    ChangeNotifierProvider(
      create: (_) => appLanguage,  // ← AppLanguage use karo
      child: const SmartBuildApp(),
    ),
  );
}

class SmartBuildApp extends StatelessWidget {
  const SmartBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 👈 TARGET COLOR: Colors.blue[900]

    final Color brandColor = Colors.blue[900]!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBuild',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
          secondary: Colors.orangeAccent,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: brandColor,
          titleTextStyle: TextStyle(
            color: brandColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: brandColor, width: 2),
          ),
        ),
        // Buttons theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
