import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arkiva/screens/home_screen.dart';
import 'package:arkiva/screens/splash_screen.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/screens/create_entreprise_screen.dart';
import 'package:arkiva/services/theme_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthStateService()),
      ],
      child: const ArkivaApp(),
    ),
  );
}

class ArkivaApp extends StatelessWidget {
  const ArkivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final authStateService = context.watch<AuthStateService>();

    return MaterialApp(
      title: 'ARKIVA',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/create-entreprise': (context) => const CreateEntrepriseScreen(),
        '/scan': (context) => const ScanScreen(),
        '/upload': (context) => const UploadScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
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
