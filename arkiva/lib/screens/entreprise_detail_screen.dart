import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/screens/edit_entreprise_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:feexpay_flutter/feexpay_flutter.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:arkiva/screens/payment_screen.dart';

class EntrepriseDetailScreen extends StatefulWidget {
  const EntrepriseDetailScreen({super.key});

  @override
  State<EntrepriseDetailScreen> createState() => _EntrepriseDetailScreenState();
}

class _EntrepriseDetailScreenState extends State<EntrepriseDetailScreen> {
  late Future<Map<String, dynamic>> _entrepriseInfoFuture;
  late Future<Map<String, dynamic>> _subscriptionInfoFuture;
  late Future<List<dynamic>> _availableSubscriptionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchEntrepriseInfo();
    _fetchSubscriptionInfo();
    _fetchAvailableSubscriptions();
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

  Future<void> _fetchSubscriptionInfo() async {
    final authStateService = Provider.of<AuthStateService>(context, listen: false);
    final token = authStateService.token;

    if (token != null) {
      _subscriptionInfoFuture = _getCurrentSubscription(token);
    } else {
      _subscriptionInfoFuture = Future.error('Token non disponible.');
    }
  }

  Future<void> _fetchAvailableSubscriptions() async {
    final authStateService = Provider.of<AuthStateService>(context, listen: false);
    final token = authStateService.token;

    if (token != null) {
      _availableSubscriptionsFuture = _getAvailableSubscriptions(token);
    } else {
      _availableSubscriptionsFuture = Future.error('Token non disponible.');
    }
  }

  Future<Map<String, dynamic>> _getCurrentSubscription(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/payments/current-subscription'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération de l\'abonnement');
    }
  }

  Future<List<dynamic>> _getAvailableSubscriptions(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/payments/subscriptions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['subscriptions'] ?? [];
    } else {
      throw Exception('Erreur lors de la récupération des abonnements');
    }
  }

  Future<void> _chooseSubscription(int subscriptionId, int armoiresSouscrites) async {
    final authStateService = Provider.of<AuthStateService>(context, listen: false);
    final token = authStateService.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Token non disponible')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/choose-subscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subscription_id': subscriptionId,
          'armoires_souscrites': armoiresSouscrites,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final paymentId = data['paiement']['payment_id'];
        // Appel backend pour générer les infos FeexPay
        final processResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/payments/process-payment'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'payment_id': paymentId.toString(),
            'moyen_paiement': 'mobile_money', // ou 'card' selon le cas
            'numero_telephone': '', // tu peux demander le numéro avant si besoin
            'custom_id': null,
          }),
        );
        if (processResponse.statusCode == 200) {
          final processData = jsonDecode(processResponse.body);
          final feexpay = processData['feexpay_data'];
          
          // Logs détaillés pour tracer le custom_id
          print('🔍 [Frontend] Réponse complète du backend:');
          print(jsonEncode(processData));
          
          print('🔍 [Frontend] Données FeexPay reçues:');
          print(jsonEncode(feexpay));
          
          // Utiliser uniquement le custom_id fourni par le backend
          String? customId;
          try {
            // Essayer d'abord de récupérer custom_id directement
            customId = feexpay['custom_id'];
            
            // Si pas trouvé, essayer de l'extraire depuis callback_info
            if (customId == null && feexpay['callback_info'] != null) {
              print('🔍 [Frontend] Tentative d\'extraction depuis callback_info...');
              final callbackInfoStr = feexpay['callback_info'] as String;
              final callbackInfoObj = jsonDecode(callbackInfoStr);
              customId = callbackInfoObj['custom_id'];
              print('🔍 [Frontend] custom_id extrait depuis callback_info: $customId');
            }
          } catch (e) {
            print('❌ [Frontend] Erreur lors de l\'extraction du custom_id: $e');
          }

          print('🔍 [Frontend] custom_id final: $customId');

          if (customId == null) {
            print('❌ [Frontend] ERREUR: custom_id manquant dans la réponse du backend');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur: custom_id manquant dans la réponse du backend.')),
            );
            return;
          }
          
          final callbackInfo = {'custom_id': customId};
          print('🔍 [Frontend] callback_info créé:');
          print(jsonEncode(callbackInfo));
          
          // Ajout d'un print pour vérifier le payload transmis à FeexPay
          print('📤 [Frontend] Payload transmis à FeexPay :');
          final feexPayPayload = {
            'token': feexpay['token'],
            'id': feexpay['id'],
            'amount': feexpay['amount'],
            'redirecturl': feexpay['redirecturl'],
            'trans_key': feexpay['trans_key'],
            'callback_info': callbackInfo,
          };
          print(jsonEncode(feexPayPayload));
          
          // Ouvre directement FeexPay
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChoicePage(
                token: feexpay['token'],
                id: feexpay['id'].toString(),
                amount: feexpay['amount'].toString(),
                redirecturl: feexpay['redirecturl'],
                trans_key: feexpay['trans_key'].toString(),
                callback_info: callbackInfo, // Passe un Map
              ),
            ),
          );
        } else {
          final errorData = jsonDecode(processResponse.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${errorData['error']}')),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${errorData['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showSubscriptionDialog(List<dynamic> subscriptions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un abonnement'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return Card(
                child: ListTile(
                  title: Text(subscription['nom']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prix: ${subscription['prix_base']} FCFA'),
                      Text('Durée: ${subscription['duree']} jours'),
                      Text('Armoires incluses: ${subscription['armoires_incluses']}'),
                      Text(subscription['description'] ?? ''),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _chooseSubscription(
                        subscription['subscription_id'],
                        subscription['armoires_incluses'],
                      );
                    },
                    child: const Text('Choisir'),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
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

  Widget _buildSubscriptionCard(Map<String, dynamic> subscriptionInfo) {
    final subscription = subscriptionInfo['subscription'];
    final usage = subscriptionInfo['usage'];
    final access = subscriptionInfo['access'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  subscription['isActive'] ? Icons.check_circle : Icons.cancel,
                  color: subscription['isActive'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'État de l\'abonnement',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subscription['isActive'] ? 'Abonnement actif' : 'Aucun abonnement actif',
              style: TextStyle(
                fontSize: 16,
                color: subscription['isActive'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subscription['expirationDate'] != null) ...[
              const SizedBox(height: 8),
              Text('Expire le: ${DateTime.parse(subscription['expirationDate']).toLocal().toString().split(' ')[0]}'),
            ],
            if (subscription['daysUntilExpiration'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Jours restants: ${subscription['daysUntilExpiration']}',
                style: TextStyle(
                  color: subscription['daysUntilExpiration'] < 7 ? Colors.orange : Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text('Armoires souscrites: ${subscription['armoiresSouscrites']}'),
            const SizedBox(height: 12),
            const Text(
              'Utilisation actuelle:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Armoires: ${usage['totalArmoires']} / ${subscription['armoiresSouscrites']}'),
            Text('Dossiers: ${usage['totalDossiers']}'),
            Text('Fichiers: ${usage['totalFichiers']}'),
            const SizedBox(height: 16),
            if (!subscription['isActive'])
              SizedBox(
                width: double.infinity,
                child: FutureBuilder<List<dynamic>>(
                  future: _availableSubscriptionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ElevatedButton(
                        onPressed: () => _showSubscriptionDialog(snapshot.data!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Souscrire à un abonnement'),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de l'entreprise
            FutureBuilder<Map<String, dynamic>>(
        future: _entrepriseInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  );
          } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune donnée d\'entreprise trouvée.'),
                    ),
                  );
          } else {
            final entreprise = snapshot.data!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            
            // Informations d'abonnement
            FutureBuilder<Map<String, dynamic>>(
              future: _subscriptionInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur abonnement: ${snapshot.error}'),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return _buildSubscriptionCard(snapshot.data!);
                } else {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune information d\'abonnement disponible.'),
              ),
            );
          }
        },
            ),
          ],
        ),
      ),
    );
  }
} 