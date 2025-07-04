import 'package:flutter/material.dart';
import 'package:arkiva/services/armoire_service.dart';
import 'package:arkiva/services/casier_service.dart';
import 'package:arkiva/services/dossier_service.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';

class DeplacementDialog extends StatefulWidget {
  final bool pourFichier; // true = déplacement fichier, false = dossier
  const DeplacementDialog({super.key, this.pourFichier = false});

  @override
  State<DeplacementDialog> createState() => _DeplacementDialogState();
}

class _DeplacementDialogState extends State<DeplacementDialog> {
  final ArmoireService _armoireService = ArmoireService();
  final CasierService _casierService = CasierService();
  final DossierService _dossierService = DossierService();

  List<dynamic> _armoires = [];
  List<dynamic> _casiers = [];
  List<dynamic> _dossiers = [];

  int? _selectedArmoireId;
  int? _selectedCasierId;
  int? _selectedDossierId;

  bool _loadingArmoires = true;
  bool _loadingCasiers = false;
  bool _loadingDossiers = false;

  @override
  void initState() {
    super.initState();
    _loadArmoires();
  }

  Future<void> _loadArmoires() async {
    setState(() => _loadingArmoires = true);
    try {
      final auth = context.read<AuthStateService>();
      final entrepriseId = auth.entrepriseId;
      if (entrepriseId != null) {
        final armoires = await _armoireService.getAllArmoiresForDeplacement(entrepriseId);
        setState(() {
          _armoires = armoires;
          _loadingArmoires = false;
        });
      }
    } catch (e) {
      setState(() => _loadingArmoires = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement armoires: $e')));
    }
  }

  Future<void> _loadCasiers(int armoireId) async {
    setState(() {
      _loadingCasiers = true;
      _casiers = [];
      _selectedCasierId = null;
      _dossiers = [];
      _selectedDossierId = null;
    });
    try {
      final casiers = await _casierService.getCasiersByArmoire(armoireId);
      setState(() {
        _casiers = casiers;
        _loadingCasiers = false;
      });
    } catch (e) {
      setState(() => _loadingCasiers = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement casiers: $e')));
    }
  }

  Future<void> _loadDossiers(int casierId) async {
    setState(() {
      _loadingDossiers = true;
      _dossiers = [];
      _selectedDossierId = null;
    });
    try {
      final auth = context.read<AuthStateService>();
      final token = auth.token;
      if (token != null) {
        final dossiers = await _dossierService.getDossiers(token, casierId);
        setState(() {
          _dossiers = dossiers;
          _loadingDossiers = false;
        });
      }
    } catch (e) {
      setState(() => _loadingDossiers = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement dossiers: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pourFichier ? 'Déplacer le fichier' : 'Déplacer le dossier'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Armoires
            _loadingArmoires
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _selectedArmoireId,
                    items: _armoires.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                          value: a['armoire_id'] as int,
                          child: Text(a['nom']),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedArmoireId = value;
                        _selectedCasierId = null;
                        _selectedDossierId = null;
                        _casiers = [];
                        _dossiers = [];
                      });
                      if (value != null) _loadCasiers(value);
                    },
                    decoration: const InputDecoration(labelText: 'Armoire de destination'),
                  ),
            const SizedBox(height: 16),
            // Casiers
            _loadingCasiers
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _selectedCasierId,
                    items: _casiers.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                          value: c.casierId ?? c['cassier_id'],
                          child: Text(c.nom ?? c['nom']),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCasierId = value;
                        _selectedDossierId = null;
                        _dossiers = [];
                      });
                      if (value != null && widget.pourFichier) _loadDossiers(value);
                    },
                    decoration: const InputDecoration(labelText: 'Casier de destination'),
                  ),
            if (widget.pourFichier) ...[
              const SizedBox(height: 16),
              // Dossiers
              _loadingDossiers
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<int>(
                      value: _selectedDossierId,
                      items: _dossiers.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                            value: d.dossierId ?? d['dossier_id'],
                            child: Text(d.nom ?? d['nom']),
                          )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDossierId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Dossier de destination'),
                    ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: (widget.pourFichier
                  ? (_selectedArmoireId != null && _selectedCasierId != null && _selectedDossierId != null)
                  : (_selectedArmoireId != null && _selectedCasierId != null))
              ? () {
                  if (widget.pourFichier) {
                    Navigator.pop(context, {
                      'armoire_id': _selectedArmoireId,
                      'cassier_id': _selectedCasierId,
                      'dossier_id': _selectedDossierId,
                    });
                  } else {
                    Navigator.pop(context, {
                      'armoire_id': _selectedArmoireId,
                      'cassier_id': _selectedCasierId,
                    });
                  }
                }
              : null,
          child: const Text('Déplacer'),
        ),
      ],
    );
  }
} 