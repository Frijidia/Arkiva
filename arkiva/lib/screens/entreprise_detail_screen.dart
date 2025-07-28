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

  // Widget helper pour les cartes d'information
  Widget _buildInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Widget helper pour les informations de l'entreprise
  Widget _buildEntrepriseInfo(Map<String, dynamic> entreprise) {
    return _buildInfoCard(
      'Informations de l\'Entreprise',
      Icons.business,
      Colors.blue[600]!,
      [
        Text(
          entreprise['nom'] ?? 'N/A',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 16),
        _buildInfoRow(Icons.email, 'Email', entreprise['email'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow(Icons.phone, 'Téléphone', entreprise['telephone'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow(Icons.location_on, 'Adresse', entreprise['adresse'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow(Icons.subscriptions, 'Plan d\'abonnement', entreprise['plan_abonnement'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow(Icons.inventory_2, 'Limite d\'armoires', entreprise['armoire_limit']?.toString() ?? 'N/A'),
      ],
    );
  }

  // Widget helper pour les lignes d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
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
    final url = '${ApiConfig.baseUrl}/api/payments/current-subscription';
    print('🔍 [DEBUG] Current subscription - URL: $url');
    print('🔍 [DEBUG] Token: ${token.substring(0, 10)}...');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('🔍 [DEBUG] Status: ${response.statusCode}');
    print('🔍 [DEBUG] Response body: ${response.body.substring(0, 100)}...');

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
    final entrepriseId = authStateService.entrepriseId;

    if (token == null || entrepriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Token ou ID entreprise manquant')),
      );
      return;
    }

    try {
      print('🔍 [DEBUG] Envoi de la requête choose-subscription...');
      print('🔍 [DEBUG] URL: ${ApiConfig.baseUrl}/api/payments/choose-subscription');
      print('🔍 [DEBUG] Body: ${jsonEncode({
        'subscription_id': subscriptionId,
        'armoires_souscrites': armoiresSouscrites,
      })}');
      
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
      
      print('🔍 [DEBUG] Réponse reçue - Status: ${response.statusCode}');
      print('🔍 [DEBUG] Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final paymentId = responseData['paiement']['payment_id'];
        
        final processResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/payments/process-payment'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'payment_id': paymentId,
            'moyen_paiement': 'mobile_money',
            'numero_telephone': '',
          }),
        );

        if (processResponse.statusCode == 200) {
          final responseData = jsonDecode(processResponse.body);
          final feexpay = responseData['feexpay_data'];
          
          if (feexpay == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: Données FeexPay manquantes')),
            );
            return;
          }
          
          final callbackInfo = {
            'subscription_id': subscriptionId,
            'entreprise_id': entrepriseId,
            'armoires_souscrites': armoiresSouscrites,
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: SafeArea(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: ChoicePage(
                      token: feexpay['token'] ?? '',
                      id: feexpay['id']?.toString() ?? '',
                      amount: feexpay['amount']?.toString() ?? '',
                      redirecturl: feexpay['redirecturl'] ?? '',
                      trans_key: feexpay['trans_key']?.toString() ?? '',
                      callback_info: callbackInfo, // Passe un Map
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          String errorMessage = 'Erreur inconnue';
          try {
            final errorData = jsonDecode(processResponse.body);
            errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur lors du traitement du paiement';
          } catch (e) {
            errorMessage = 'Erreur lors du traitement du paiement: ${processResponse.statusCode}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        String errorMessage = 'Erreur inconnue';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur lors du choix de l\'abonnement';
        } catch (e) {
          errorMessage = 'Erreur lors du choix de l\'abonnement: ${response.statusCode}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Exception lors de la souscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: $e')),
      );
    }
  }

  void _showArmoiresDialog(int subscriptionId) {
    int selectedArmoires = 2;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Nombre d\'armoires'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Combien d\'armoires souhaitez-vous souscrire ?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (selectedArmoires > 2) {
                        setState(() {
                          selectedArmoires--;
                        });
                      }
                    },
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$selectedArmoires',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedArmoires++;
                      });
                    },
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _chooseSubscription(subscriptionId, selectedArmoires);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDialog(List<dynamic> subscriptions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.subscriptions, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Choisir un abonnement'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.subscriptions, color: Colors.blue[600]),
                  ),
                  title: Text(
                    subscription['nom'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      _buildSubscriptionInfo('Prix', '${subscription['prix_base']} FCFA', Icons.payment),
                      _buildSubscriptionInfo('Durée', '${subscription['duree']} jours', Icons.calendar_today),
                      _buildSubscriptionInfo('Armoires', '${subscription['armoires_incluses']}', Icons.inventory_2),
                      if (subscription['description'] != null)
                        _buildSubscriptionInfo('Description', subscription['description'], Icons.description),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showArmoiresDialog(subscription['subscription_id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Choisir'),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
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

    return _buildInfoCard(
      'État de l\'Abonnement',
      subscription['isActive'] ? Icons.check_circle : Icons.cancel,
      subscription['isActive'] ? Colors.green[600]! : Colors.red[600]!,
      [
        Row(
              children: [
                Icon(
                  subscription['isActive'] ? Icons.check_circle : Icons.cancel,
                  color: subscription['isActive'] ? Colors.green : Colors.red,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              subscription['isActive'] ? 'Abonnement actif' : 'Aucun abonnement actif',
              style: TextStyle(
                fontSize: 16,
                color: subscription['isActive'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
            if (subscription['expirationDate'] != null) ...[
          _buildInfoRow(Icons.calendar_today, 'Expire le', DateTime.parse(subscription['expirationDate']).toLocal().toString().split(' ')[0]),
          SizedBox(height: 8),
            ],
            if (subscription['daysUntilExpiration'] != null) ...[
          _buildInfoRow(
            Icons.timer,
            'Jours restants',
            '${subscription['daysUntilExpiration']}',
          ),
          SizedBox(height: 8),
        ],
        _buildInfoRow(Icons.inventory_2, 'Armoires souscrites', '${subscription['armoiresSouscrites']}'),
        SizedBox(height: 16),
        Text(
              'Utilisation actuelle:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 8),
        _buildInfoRow(Icons.inventory_2, 'Armoires', '${usage['totalArmoires']} / ${subscription['armoiresSouscrites']}'),
        _buildInfoRow(Icons.folder, 'Dossiers', '${usage['totalDossiers']}'),
        _buildInfoRow(Icons.description, 'Fichiers', '${usage['totalFichiers']}'),
        SizedBox(height: 16),
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
                      backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                    child: Text('Souscrire à un abonnement'),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else {
                  return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Détails de l\'Entreprise',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _entrepriseInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de l'entreprise
            FutureBuilder<Map<String, dynamic>>(
        future: _entrepriseInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: EdgeInsets.all(40),
              child: Column(
                children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Chargement des informations...'),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildInfoCard(
                    'Erreur',
                    Icons.error,
                    Colors.red[600]!,
                    [
                      Text('Erreur: ${snapshot.error}'),
                    ],
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return _buildInfoCard(
                    'Aucune donnée',
                    Icons.info,
                    Colors.orange[600]!,
                    [
                      Text('Aucune donnée d\'entreprise trouvée.'),
                    ],
                  );
                } else {
                  return _buildEntrepriseInfo(snapshot.data!);
                }
              },
            ),
            
            SizedBox(height: 20),
            
            // Informations d'abonnement
            FutureBuilder<Map<String, dynamic>>(
              future: _subscriptionInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Chargement de l\'abonnement...'),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildInfoCard(
                    'Erreur Abonnement',
                    Icons.error,
                    Colors.red[600]!,
                    [
                      Text('Erreur abonnement: ${snapshot.error}'),
                    ],
                  );
                } else if (snapshot.hasData) {
                  return _buildSubscriptionCard(snapshot.data!);
                } else {
                  return _buildInfoCard(
                    'Aucun Abonnement',
                    Icons.info,
                    Colors.orange[600]!,
                    [
                      Text('Aucune information d\'abonnement disponible.'),
                    ],
            );
          }
        },
            ),
            
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
} 