import 'package:flutter/material.dart';
import 'package:arkiva/services/armoire_service.dart';
import 'package:arkiva/services/dossier_service.dart';
import 'package:arkiva/services/casier_service.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum TypeDeplacement {
  casier,   // Casier vers armoire
  dossier,  // Dossier vers casier
  fichier   // Fichier vers dossier
}

class DeplacementDialog extends StatefulWidget {
  final TypeDeplacement type;
  final String titre;
  final String nomElement;
  final int elementId;
  final int? destinationActuelleId;
  final Function() onDeplacementReussi;

  const DeplacementDialog({
    super.key,
    required this.type,
    required this.titre,
    required this.nomElement,
    required this.elementId,
    this.destinationActuelleId,
    required this.onDeplacementReussi,
  });

  @override
  State<DeplacementDialog> createState() => _DeplacementDialogState();
}

class _DeplacementDialogState extends State<DeplacementDialog> {
  final ArmoireService _armoireService = ArmoireService();
  final DossierService _dossierService = DossierService();
  final CasierService _casierService = CasierService();
  final DocumentService _documentService = DocumentService();
  
  List<Map<String, dynamic>> _destinations = [];
  Map<String, dynamic>? _destinationSelectionnee;
  bool _isLoading = true;
  bool _isDeplacing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerDestinations();
  }

  Future<void> _chargerDestinations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Token ou entreprise ID manquant');
      }

      switch (widget.type) {
        case TypeDeplacement.casier:
          final authState = context.read<AuthStateService>();
          final entrepriseId = authState.entrepriseId;
          if (entrepriseId == null) {
            setState(() {
              _isLoading = false;
              _errorMessage = "Impossible de charger les armoires : entrepriseId manquant.";
            });
            return;
          }
          final armoires = await _armoireService.getAllArmoiresForDeplacement(entrepriseId);
          // Filtrer l'armoire actuelle
          _destinations = armoires.where((armoire) => 
            armoire['armoire_id'] != widget.destinationActuelleId
          ).toList();
          break;

        case TypeDeplacement.dossier:
          final authState = context.read<AuthStateService>();
          final entrepriseId = authState.entrepriseId;
          if (entrepriseId == null) {
            setState(() {
              _isLoading = false;
              _errorMessage = "Impossible de charger les casiers : entrepriseId manquant.";
            });
            return;
          }
          final casiers = await _armoireService.getAllCasiers(entrepriseId);
          // Filtrer le casier actuel
          _destinations = casiers.where((casier) => 
            casier['cassier_id'] != widget.destinationActuelleId
          ).toList();
          break;

        case TypeDeplacement.fichier:
          // Charger tous les dossiers pour le déplacement de fichier
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/dosier/all/$entrepriseId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            // Filtrer le dossier actuel
            _destinations = data.where((dossier) => 
              dossier['dossier_id'] != widget.destinationActuelleId
            ).cast<Map<String, dynamic>>().toList();
          } else {
            throw Exception('Erreur lors du chargement des dossiers');
          }
          break;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getNomDestination(Map<String, dynamic> destination) {
    switch (widget.type) {
      case TypeDeplacement.casier:
        return destination['nom'] ?? 'Armoire sans nom';
      case TypeDeplacement.dossier:
        final nom = destination['nom'] ?? 'Casier sans nom';
        final sousTitre = destination['sous_titre'];
        return sousTitre != null && sousTitre.isNotEmpty 
          ? '$nom - $sousTitre' 
          : nom;
      case TypeDeplacement.fichier:
        return destination['nom'] ?? 'Dossier sans nom';
    }
  }

  Future<void> _effectuerDeplacement() async {
    if (_destinationSelectionnee == null) return;

    setState(() {
      _isDeplacing = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;

      if (token == null) {
        throw Exception('Token manquant');
      }

      switch (widget.type) {
        case TypeDeplacement.casier:
          await _casierService.deplacerCasier(
            widget.elementId,
            _destinationSelectionnee!['armoire_id'],
          );
          break;

        case TypeDeplacement.dossier:
          await _dossierService.deplacerDossier(
            token,
            widget.elementId,
            _destinationSelectionnee!['cassier_id'],
          );
          break;

        case TypeDeplacement.fichier:
          await _documentService.deplacerFichier(
            token,
            widget.elementId.toString(),
            _destinationSelectionnee!['dossier_id'],
          );
          break;
      }

      // Fermer la boîte de dialogue et notifier le succès
      Navigator.of(context).pop(true);
      widget.onDeplacementReussi();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.nomElement} déplacé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isDeplacing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement des destinations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _chargerDestinations,
                    child: Text('Réessayer'),
                  ),
                ],
              )
            : _destinations.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    Text('Aucune destination disponible'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sélectionnez la nouvelle destination pour "${widget.nomElement}" :',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _destinations.length,
                        itemBuilder: (context, index) {
                          final destination = _destinations[index];
                          final nom = _getNomDestination(destination);
                          final isSelected = _destinationSelectionnee == destination;
                          
                          return ListTile(
                            leading: Icon(
                              widget.type == TypeDeplacement.casier 
                                ? Icons.warehouse 
                                : widget.type == TypeDeplacement.dossier 
                                  ? Icons.inventory_2 
                                  : Icons.folder,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Text(nom),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _destinationSelectionnee = destination;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeplacing ? null : () => Navigator.of(context).pop(false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isDeplacing || _destinationSelectionnee == null || _destinations.isEmpty
            ? null 
            : _effectuerDeplacement,
          child: _isDeplacing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Déplacer'),
        ),
      ],
    );
  }
} 