import 'package:flutter/material.dart';
import 'package:feexpay_flutter/feexpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final String paymentId;
  final String authToken;

  const PaymentScreen({
    Key? key,
    required this.paymentId,
    required this.authToken,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedPaymentMethod = 'MTN_MOBILE_MONEY';
  final TextEditingController _phoneController = TextEditingController();

  final Map<String, String> _paymentMethods = {
    'MTN_MOBILE_MONEY': 'MTN Mobile Money',
    'MOOV_MONEY': 'Moov Money',
    'CELTIIS_CASH': 'Celtiis Cash',
    'CARTE_BANCAIRE': 'Carte Bancaire',
  };

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Appeler l'API backend pour obtenir les données FeexPay
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/payments/process-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'payment_id': widget.paymentId,
          'moyen_paiement': _selectedPaymentMethod,
          'numero_telephone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final feexpayData = data['feexpay_data'];
          
          // 2. Lancer l'interface FeexPay
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChoicePage(
                token: feexpayData['token'],
                id: feexpayData['id'],
                amount: feexpayData['amount'].toString(),
                redirecturl: feexpayData['redirecturl'],
                trans_key: feexpayData['trans_key'],
                callback_info: feexpayData['callback_info'],
              ),
            ),
          );

          // 3. Retour à la page de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paiement terminé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Naviguer vers la page de succès
          Navigator.pushReplacementNamed(context, '/payment-success');
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du traitement du paiement');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
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
        title: Text('Paiement Arkiva'),
        backgroundColor: Color(0xFF112C56),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations de paiement
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de paiement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('ID de paiement: ${widget.paymentId}'),
                    Text('Token: ${widget.authToken.substring(0, 20)}...'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),

            // Sélection du moyen de paiement
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moyen de paiement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ..._paymentMethods.entries.map((entry) => RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    )).toList(),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),

            // Numéro de téléphone (optionnel)
            if (_selectedPaymentMethod.contains('MOBILE'))
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Numéro de téléphone (optionnel)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '22507000000',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Spacer(),

            // Bouton de paiement
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF112C56),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Payer maintenant',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
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

// Page de succès
class PaymentSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement Réussi'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 24),
            Text(
              'Paiement effectué avec succès !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Votre abonnement Arkiva est maintenant actif.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF112C56),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Retour à l\'accueil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 