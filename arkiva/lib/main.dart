import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arkiva/screens/home_screen.dart';
import 'package:arkiva/screens/splash_screen.dart';
import 'package:arkiva/services/theme_service.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/services/animation_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const ArkivaApp(),
    ),
  );
}

class ArkivaApp extends StatelessWidget {
  const ArkivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'ARKIVA',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Empêche le redimensionnement du texte
          ),
          child: child!,
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      AnimationService.slideTransition(screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARKIVA'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimationService.listItemAnimation(
              index: 0,
              child: const Text(
                'Bienvenue sur ARKIVA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimationService.listItemAnimation(
              index: 1,
              child: AnimationService.scaleOnTap(
                onTap: () => _navigateToScreen(context, const ScanScreen()),
                child: ElevatedButton(
                  onPressed: null, // Le onTap est géré par scaleOnTap
                  child: const Text('Scanner un document'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimationService.listItemAnimation(
              index: 2,
              child: AnimationService.scaleOnTap(
                onTap: () => _navigateToScreen(context, const UploadScreen()),
                child: ElevatedButton(
                  onPressed: null, // Le onTap est géré par scaleOnTap
                  child: const Text('Téléverser un fichier'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
