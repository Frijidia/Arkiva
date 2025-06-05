import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';

class EditEntrepriseScreen extends StatefulWidget {
  final Map<String, dynamic> entrepriseData;

  const EditEntrepriseScreen({Key? key, required this.entrepriseData}) : super(key: key);

  @override
  _EditEntrepriseScreenState createState() => _EditEntrepriseScreenState();
}

class _EditEntrepriseScreenState extends State<EditEntrepriseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  // Ajoutez d'autres contrôleurs pour les champs modifiables si nécessaire

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.entrepriseData['nom']);
    _emailController = TextEditingController(text: widget.entrepriseData['email']);
    _telephoneController = TextEditingController(text: widget.entrepriseData['telephone']);
    _adresseController = TextEditingController(text: widget.entrepriseData['adresse']);
    // Initialisez d'autres contrôleurs ici
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    // Supprimez d'autres contrôleurs ici
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authStateService = Provider.of<AuthStateService>(context, listen: false);
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
         // Gérer l'erreur (utilisateur non connecté ou pas d'entreprise)
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: non authentifié ou entreprise introuvable.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final updatedData = {
        'nom': _nomController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text,
        'adresse': _adresseController.text,
        // Ajoutez d'autres champs modifiables ici
      };

      try {
        await AuthService().updateEntreprise(entrepriseId, updatedData, token);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations de l\'entreprise mises à jour avec succès !')),
        );
        Navigator.pop(context, true);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la mise à jour: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'Entreprise'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(labelText: 'Nom de l\'entreprise'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom de l\'entreprise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                     TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Veuillez entrer l\'email';
                         }
                         return null;
                       },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Veuillez entrer le numéro de téléphone';
                         }
                         return null;
                       },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(labelText: 'Adresse'),
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Veuillez entrer l\'adresse';
                         }
                         return null;
                       },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Enregistrer les modifications'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 