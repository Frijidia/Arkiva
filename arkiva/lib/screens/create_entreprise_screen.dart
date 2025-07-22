import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../services/auth_service.dart';
import '../services/auth_state_service.dart';
import '../models/entreprise.dart';

class CreateEntrepriseScreen extends StatefulWidget {
  const CreateEntrepriseScreen({Key? key}) : super(key: key);

  @override
  _CreateEntrepriseScreenState createState() => _CreateEntrepriseScreenState();
}

class _CreateEntrepriseScreenState extends State<CreateEntrepriseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  // Champs du formulaire d'entreprise
  final _nomController = TextEditingController();
  final _entrepriseEmailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  File? _logoFile;

  @override
  void dispose() {
    _nomController.dispose();
    _entrepriseEmailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _logoFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleCreateEntreprise() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔄 Début de la création d\'entreprise...');
    setState(() => _isLoading = true);

    try {
      print('📝 Validation du formulaire d\'entreprise...');
      final entrepriseData = {
        'nom': _nomController.text,
        'email': _entrepriseEmailController.text,
        'telephone': _telephoneController.text,
        'adresse': _adresseController.text,
      };

      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        print('❌ Erreur: Token d\'authentification manquant.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token d\'authentification manquant.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_logoFile != null) {
         print('📎 Fichier logo sélectionné: \\${_logoFile!.path}');
         final response = await _authService.createEntrepriseWithLogo(entrepriseData, _logoFile!, token);
         final entrepriseId = response['entreprise']['entreprise_id'];
         final user = response['user'];
         authStateService.setEntrepriseAndUser(entrepriseId, user);
       } else {
          final entreprise = Entreprise(
             nom: _nomController.text,
             email: _entrepriseEmailController.text,
             telephone: _telephoneController.text,
             adresse: _adresseController.text,
             logoUrl: '',
          );
         final response = await _authService.createEntreprise(entreprise, token);
         final entrepriseId = response['entreprise']['entreprise_id'];
         final user = response['user'];
         authStateService.setEntrepriseAndUser(entrepriseId, user);
       }

      print('✅ Création d\'entreprise réussie, redirection vers l\'accueil...');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('❌ Erreur lors de la création d\'entreprise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer votre entreprise'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                controller: _entrepriseEmailController,
                decoration: const InputDecoration(labelText: 'Email de l\'entreprise'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'email de l\'entreprise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _logoFile == null
                          ? 'Aucun fichier logo sélectionné'
                          : 'Fichier logo: ${_logoFile!.path.split('/').last}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickLogo,
                    child: const Text('Choisir un logo'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateEntreprise,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Créer l\'entreprise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 