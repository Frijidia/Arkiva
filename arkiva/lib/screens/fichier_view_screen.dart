import 'package:flutter/material.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:arkiva/config/api_config.dart';

class FichierViewScreen extends StatelessWidget {
  final Map<String, dynamic> doc;
  const FichierViewScreen({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entrepriseId = context.read<AuthStateService>().entrepriseId;
    final token = context.read<AuthStateService>().token;
    final nomAffiche = doc['originalfilename'] ?? doc['nom'] ?? 'Document';
    final armoire = doc['armoire'] ?? '';
    final casier = doc['casier'] ?? '';
    final dossier = doc['dossier'] ?? '';
    final cheminAffiche = [armoire, casier, dossier].where((e) => e != null && e.toString().isNotEmpty).join(' > ');
    final fichierId = doc['fichier_id'];
    final url = (fichierId != null && entrepriseId != null && token != null)
        ? '${ApiConfig.baseUrl}/api/fichier/$fichierId/$entrepriseId?token=$token'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(nomAffiche),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 48, color: Colors.blue[700]),
                const SizedBox(height: 16),
                Text(nomAffiche, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(cheminAffiche, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir / Télécharger'),
                  onPressed: url.isNotEmpty
                      ? () async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 