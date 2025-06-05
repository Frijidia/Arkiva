import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/screens/edit_entreprise_screen.dart';

class EntrepriseDetailScreen extends StatefulWidget {
  const EntrepriseDetailScreen({super.key});

  @override
  State<EntrepriseDetailScreen> createState() => _EntrepriseDetailScreenState();
}

class _EntrepriseDetailScreenState extends State<EntrepriseDetailScreen> {
  late Future<Map<String, dynamic>> _entrepriseInfoFuture;

  @override
  void initState() {
    super.initState();
    _fetchEntrepriseInfo();
  }

  Future<void> _fetchEntrepriseInfo() async {
    final authStateService = Provider.of<AuthStateService>(context, listen: false);
    final entrepriseId = authStateService.entrepriseId;
    final token = authStateService.token;

    if (entrepriseId != null && token != null) {
      _entrepriseInfoFuture = AuthService().getEntrepriseInfo(entrepriseId, token);
    } else {
      // Gérer le cas où l'ID de l'entreprise ou le token n'est pas disponible
      _entrepriseInfoFuture = Future.error('ID entreprise ou token non disponible.');
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> currentData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEntrepriseScreen(entrepriseData: currentData),
      ),
    );

    if (result == true) {
      _fetchEntrepriseInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'Entreprise'),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _entrepriseInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditScreen(snapshot.data!),
                  tooltip: 'Modifier l\'entreprise',
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _entrepriseInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Aucune donnée d\'entreprise trouvée.'));
          } else {
            final entreprise = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entreprise['nom'] ?? 'N/A',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Email: ${entreprise['email'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Téléphone: ${entreprise['telephone'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Adresse: ${entreprise['adresse'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Plan d\'abonnement: ${entreprise['plan_abonnement'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Limite d\'armoires: ${entreprise['armoire_limit'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  // Afficher d'autres informations si nécessaire
                ],
              ),
            );
          }
        },
      ),
    );
  }
} 