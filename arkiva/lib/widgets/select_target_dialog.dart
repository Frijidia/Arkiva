import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/config/api_config.dart';

class SelectTargetDialog extends StatefulWidget {
  final String selectedType;
  const SelectTargetDialog({super.key, required this.selectedType});

  @override
  State<SelectTargetDialog> createState() => _SelectTargetDialogState();
}

class _SelectTargetDialogState extends State<SelectTargetDialog> {
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;
  String? _selectedFichier;
  
  List<Map<String, dynamic>> _armoires = [];
  List<Map<String, dynamic>> _casiers = [];
  List<Map<String, dynamic>> _dossiers = [];
  List<Map<String, dynamic>> _fichiers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArmoires();
  }

  Future<void> _loadArmoires() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/armoire/$entrepriseId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _armoires = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCasiers(String armoireId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/casier/$armoireId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _casiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDossiers(String casierId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/dosier/$casierId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _dossiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFichiers(String dossierId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/fichier/$dossierId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _fichiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int? get _selectedCibleId {
    switch (widget.selectedType) {
      case 'armoire':
        return _selectedArmoire != null ? int.tryParse(_selectedArmoire!) : null;
      case 'casier':
        return _selectedCasier != null ? int.tryParse(_selectedCasier!) : null;
      case 'dossier':
        return _selectedDossier != null ? int.tryParse(_selectedDossier!) : null;
      case 'fichier':
        return _selectedFichier != null ? int.tryParse(_selectedFichier!) : null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sélectionner ${_getTypeDisplayName(widget.selectedType)}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedType == 'armoire' || widget.selectedType == 'casier' || widget.selectedType == 'dossier' || widget.selectedType == 'fichier')
              DropdownButtonFormField<String>(
                value: _selectedArmoire,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner une armoire',
                  prefixIcon: Icon(Icons.warehouse),
                ),
                items: _armoires.map((armoire) => DropdownMenuItem(
                  value: armoire['armoire_id'].toString(),
                  child: Text(armoire['nom']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArmoire = value;
                    _selectedCasier = null;
                    _selectedDossier = null;
                    _selectedFichier = null;
                    _casiers.clear();
                    _dossiers.clear();
                    _fichiers.clear();
                  });
                  if (value != null) {
                    _loadCasiers(value);
                  }
                },
              ),
            
            if (widget.selectedType == 'casier' || widget.selectedType == 'dossier' || widget.selectedType == 'fichier')
              if (_selectedArmoire != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCasier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un casier',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  items: _casiers.map((casier) => DropdownMenuItem(
                    value: casier['cassier_id'].toString(),
                    child: Text('${casier['nom']}${casier['sous_titre'] != null && casier['sous_titre'].isNotEmpty ? ' - ${casier['sous_titre']}' : ''}'),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCasier = value;
                      _selectedDossier = null;
                      _selectedFichier = null;
                      _dossiers.clear();
                      _fichiers.clear();
                    });
                    if (value != null) {
                      _loadDossiers(value);
                    }
                  },
                ),
              ],
            
            if (widget.selectedType == 'dossier' || widget.selectedType == 'fichier')
              if (_selectedCasier != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDossier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un dossier',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: _dossiers.map((dossier) => DropdownMenuItem(
                    value: dossier['dossier_id'].toString(),
                    child: Text(dossier['nom']),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDossier = value;
                      _selectedFichier = null;
                      _fichiers.clear();
                    });
                    if (value != null && widget.selectedType == 'fichier') {
                      _loadFichiers(value);
                    }
                  },
                ),
              ],
            
            if (widget.selectedType == 'fichier')
              if (_selectedDossier != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFichier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un fichier',
                    prefixIcon: Icon(Icons.description),
                  ),
                  items: _fichiers.map((fichier) => DropdownMenuItem(
                    value: fichier['id'].toString(),
                    child: Text(fichier['nom'] ?? fichier['originalfilename'] ?? 'Fichier'),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFichier = value;
                    });
                  },
                ),
              ],
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedCibleId != null
              ? () {
                  Navigator.pop(context, {
                    'cibleId': _selectedCibleId,
                  });
                }
              : null,
          child: const Text('Sélectionner'),
        ),
      ],
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'fichier':
        return 'un fichier';
      case 'dossier':
        return 'un dossier';
      case 'casier':
        return 'un casier';
      case 'armoire':
        return 'une armoire';
      default:
        return type;
    }
  }
} 