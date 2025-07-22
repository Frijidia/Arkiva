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
import 'package:arkiva/screens/backups_screen.dart';
import 'package:arkiva/screens/versions_screen.dart';
import 'package:arkiva/screens/restorations_screen.dart';
import 'screens/payment_screen.dart';

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
        '/backups': (context) => const BackupsScreen(),
        '/versions': (context) => const VersionsScreen(),
        '/restorations': (context) => const RestorationsScreen(),
        '/payment': (context) => PaymentScreen(
          paymentId: '1', // ID de test
          authToken: 'your_test_token_here', // Token de test
        ),
        '/payment-success': (context) => PaymentSuccessScreen(),
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

// Écran de test pour le paiement
class PaymentTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Paiement FeexPay'),
        backgroundColor: Color(0xFF112C56),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 100,
              color: Color(0xFF112C56),
            ),
            SizedBox(height: 24),
            Text(
              'Test Intégration FeexPay',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Cliquez sur le bouton ci-dessous pour tester le paiement',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/payment');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF112C56),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Tester le Paiement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
