import 'package:flutter/material.dart';
import '../models/armoire.dart';
import '../services/armoire_service.dart';
import 'casiers_screen.dart';
import '../services/auth_state_service.dart';
import 'package:provider/provider.dart';
import '../services/casier_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class ArmoiresScreen extends StatefulWidget {
  final int entrepriseId;
  final int userId;

  const ArmoiresScreen({
    Key? key,
    required this.entrepriseId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ArmoiresScreen> createState() => _ArmoiresScreenState();
}

class _ArmoiresScreenState extends State<ArmoiresScreen> {
  final ArmoireService _armoireService = ArmoireService();
  List<Armoire> _armoires = [];
  bool _isLoading = true;
  String? _error;
  bool _abonnementActif = true;
  bool _abonnementCharge = false;

  @override
  void initState() {
    super.initState();
    _checkAbonnement();
    _loadArmoires();
  }

  Future<void> _checkAbonnement() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/payments/current-subscription'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _abonnementActif = data['subscription']?['isActive'] ?? false;
            _abonnementCharge = true;
          });
        } else {
          setState(() {
            _abonnementActif = false;
            _abonnementCharge = true;
          });
        }
      } else {
        setState(() {
          _abonnementActif = false;
          _abonnementCharge = true;
        });
      }
    } catch (e) {
      setState(() {
        _abonnementActif = false;
        _abonnementCharge = true;
      });
    }
  }

  Future<void> _loadArmoires() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final armoires = await _armoireService.getAllArmoires(widget.entrepriseId);
      setState(() {
        _armoires = armoires;
      });

      // Mettre à jour le compteur d'armoires dans AuthStateService
      context.read<AuthStateService>().setArmoireCount(armoires.length);

      // Calculer et mettre à jour le nombre total de casiers
      int totalCasiers = 0;
      final casierService = CasierService(); // Créer une instance du service Casier
      for (final armoire in armoires) {
        // Pour chaque armoire, récupérer ses casiers
        final casiers = await casierService.getCasiersByArmoire(armoire.armoireId);
        totalCasiers += casiers.length;
      }

      // Mettre à jour le compteur de casiers dans AuthStateService
      context.read<AuthStateService>().setCasierCount(totalCasiers);

      setState(() {
        _isLoading = false; // Fin du chargement après avoir tout récupéré
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createArmoire() async {
    try {
      await _armoireService.createArmoire(widget.userId, widget.entrepriseId);
      await _loadArmoires();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: $e')),
      );
    }
  }

  Future<void> _renameArmoire(Armoire armoire) async {
    final TextEditingController controller = TextEditingController(text: armoire.sousTitre);
    
    final String? newSousTitre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer l\'armoire'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Sous-titre',
            hintText: 'Entrez un sous-titre pour l\'armoire',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    if (newSousTitre != null && newSousTitre != armoire.sousTitre) {
      try {
        await _armoireService.renameArmoire(armoire.armoireId, newSousTitre);
        await _loadArmoires();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du renommage: $e')),
        );
      }
    }
  }

  Future<void> _deleteArmoire(Armoire armoire) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'armoire'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${armoire.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _armoireService.deleteArmoire(armoire.armoireId);
        await _loadArmoires();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Armoires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAbonnement();
              _loadArmoires();
            },
          ),
        ],
      ),
      body: _isLoading || !_abonnementCharge
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    if (!_abonnementActif)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Vous ne pouvez pas accéder à vos armoires car votre abonnement n'est pas actif.",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: _armoires.isEmpty
                  ? const Center(child: Text('Aucune armoire disponible'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _armoires.length,
                      itemBuilder: (context, index) {
                        final armoire = _armoires[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              InkWell(
                                    onTap: _abonnementActif
                                        ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CasiersScreen(
                                    armoireId: armoire.armoireId,
                                    armoireNom: armoire.nom,
                                    entrepriseId: widget.entrepriseId,
                                  ),
                                ),
                              );
                                          }
                                        : () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Abonnement inactif : accès aux armoires verrouillé.'),
                                              ),
                                            );
                                          },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          _abonnementActif ? Icons.folder : Icons.lock,
                                          size: 48,
                                          color: _abonnementActif ? Colors.blue[700] : Colors.grey[600],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        armoire.nom,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          textAlign: TextAlign.center,
                                      ),
                                        if (!_abonnementActif)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'Abonnement requis',
                                              style: TextStyle(color: Colors.red, fontSize: 12),
                                            ),
                                      ),
                                    ],
                                    ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Supprimer l\'armoire',
                                  onPressed: () => _deleteArmoire(armoire),
                                ),
                              ),
                            ],
                                  ),
                                );
                              },
                                  ),
                                ),
                              ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createArmoire,
        child: const Icon(Icons.add),
      ),
    );
  }
} 