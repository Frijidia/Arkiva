import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:feexpay_flutter/feexpay_flutter.dart';
import 'package:arkiva/config/api_config.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentId;
  final String authToken;

  const PaymentScreen({
    super.key,
    required this.paymentId,
    required this.authToken,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _paymentInfo;
  String? _selectedPaymentMethod;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customIdController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'mobile_money', 'name': 'Mobile Money', 'icon': Icons.phone_android},
    {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card},
    {'id': 'bank_transfer', 'name': 'Virement bancaire', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les informations de paiement depuis le backend
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/current-subscription'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _paymentInfo = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des informations de paiement');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un moyen de paiement')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'mobile_money' && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro de téléphone')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/process-payment'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'payment_id': widget.paymentId,
          'moyen_paiement': _selectedPaymentMethod,
          'numero_telephone': _phoneController.text,
          'custom_id': _customIdController.text.isNotEmpty ? _customIdController.text : null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final feexpay = data['feexpay_data'];
        final callbackInfo = feexpay['callback_info'];
        final callbackInfoMap = callbackInfo is String ? jsonDecode(callbackInfo) : callbackInfo;
        // Ajout d'un log pour vérifier le payload transmis à FeexPay
        print('Payload transmis à ChoicePage (FeexPay):');
        print({
          'token': feexpay['token'],
          'id': feexpay['id'],
          'amount': feexpay['amount'],
          'redirecturl': feexpay['redirecturl'],
          'trans_key': feexpay['trans_key'],
          'callback_info': callbackInfoMap,
        });
        // Ouvre directement l'interface FeexPay Flutter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChoicePage(
              token: feexpay['token'],
              id: feexpay['id'],
              amount: feexpay['amount'],
              redirecturl: feexpay['redirecturl'],
              trans_key: feexpay['trans_key'],
              callback_info: callbackInfoMap,
            ),
          ),
        );
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement d\'abonnement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Informations de l'abonnement
                  if (_paymentInfo != null) ...[
            Card(
              child: Padding(
                        padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            const Text(
                              'Récapitulatif de l\'abonnement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                            const SizedBox(height: 12),
                            Text('Armoires souscrites: ${_paymentInfo!['subscription']['armoiresSouscrites']}'),
                            if (_paymentInfo!['subscription']['expirationDate'] != null)
                              Text('Expire le: ${DateTime.parse(_paymentInfo!['subscription']['expirationDate']).toLocal().toString().split(' ')[0]}'),
                  ],
                ),
              ),
            ),
                    const SizedBox(height: 16),
                  ],

            // Sélection du moyen de paiement
            Card(
              child: Padding(
                      padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          const Text(
                      'Moyen de paiement',
                      style: TextStyle(
                              fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                          const SizedBox(height: 12),
                          ..._paymentMethods.map((method) => RadioListTile<String>(
                            value: method['id'],
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                                _selectedPaymentMethod = value;
                        });
                      },
                            title: Row(
                              children: [
                                Icon(method['icon']),
                                const SizedBox(width: 8),
                                Text(method['name']),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
                  const SizedBox(height: 16),

                  // Numéro de téléphone (pour Mobile Money)
                  if (_selectedPaymentMethod == 'mobile_money') ...[
              Card(
                child: Padding(
                        padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            const Text(
                              'Numéro de téléphone',
                        style: TextStyle(
                                fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                            const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Numéro de téléphone',
                                hintText: 'Ex: 22507012345',
                                border: OutlineInputBorder(),
                              ),
                        keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ID personnalisé (optionnel)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID personnalisé (optionnel)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID personnalisé',
                              hintText: 'Ex: MON_ID_123',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  const SizedBox(height: 24),

            // Bouton de paiement
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Procéder au paiement',
                              style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page de succès
class PaymentSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Redirection automatique vers l'accueil après un court délai
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 24),
            Text('Paiement réussi !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Redirection vers l\'accueil...'),
          ],
        ),
      ),
    );
  }
} 