import 'package:flutter/material.dart';
import '../models/armoire.dart';
import '../services/armoire_service.dart';
import 'casiers_screen.dart';
import '../services/auth_state_service.dart';
import '../services/responsive_service.dart';
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

  // Widgets helpers pour un design moderne
  Widget _buildModernCard({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: padding ?? EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: color != null ? LinearGradient(
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildArmoireCard(Armoire armoire) {
    return _buildModernCard(
      color: _abonnementActif ? Colors.purple[50] : Colors.grey[50],
      padding: EdgeInsets.all(ResponsiveService.getCardPadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône avec container moderne
          Container(
            padding: EdgeInsets.all(ResponsiveService.getCardPadding(context)),
            decoration: BoxDecoration(
              color: _abonnementActif 
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveService.getBorderRadius(context)),
              border: Border.all(
                color: _abonnementActif 
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              _abonnementActif ? Icons.warehouse_rounded : Icons.lock_rounded,
              size: ResponsiveService.getIconSize(context) * 1.2,
              color: _abonnementActif 
                  ? Colors.purple[600]
                  : Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveService.getCardPadding(context)),
          
          // Nom de l'armoire
          Text(
            armoire.nom,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveService.getFontSize(context, baseSize: 15),
              color: _abonnementActif 
                  ? Colors.purple[700]
                  : Colors.grey[700],
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Sous-titre si disponible
          if (armoire.sousTitre.isNotEmpty) ...[
            SizedBox(height: ResponsiveService.getCardPadding(context) * 0.4),
            Text(
              armoire.sousTitre,
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                color: Colors.grey[500],
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Badge d'abonnement si nécessaire
          if (!_abonnementActif) ...[
            SizedBox(height: ResponsiveService.getCardPadding(context) * 0.6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveService.getCardPadding(context) * 0.5,
                vertical: ResponsiveService.getCardPadding(context) * 0.2,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveService.getBorderRadius(context)),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Abonnement requis',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 10),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
          
          SizedBox(height: ResponsiveService.getCardPadding(context)),
          
          // Bouton d'action moderne
          if (_abonnementActif)
            Container(
              width: double.infinity,
              child: ResponsiveService.responsiveButton(
                context: context,
                onPressed: () {
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
                },
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded, 
                      size: ResponsiveService.getIconSize(context) * 0.6,
                    ),
                    SizedBox(width: ResponsiveService.getCardPadding(context) * 0.4),
                    Text(
                      'Ouvrir',
                      style: TextStyle(
                        fontSize: ResponsiveService.getFontSize(context, baseSize: 13),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Renommer l\'armoire'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Sous-titre',
            hintText: 'Entrez un sous-titre pour l\'armoire',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.warehouse, color: Colors.purple[600]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Renommer'),
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
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Supprimer l\'armoire'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer ${armoire.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
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

  Widget _buildSubscriptionWarning() {
    return _buildModernCard(
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Vous ne pouvez pas accéder à vos armoires car votre abonnement n'est pas actif.",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: _buildModernCard(
        color: Colors.purple[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse,
              size: 64,
              color: Colors.purple[400],
            ),
            SizedBox(height: 16),
            Text(
              'Aucune armoire disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre première armoire pour commencer',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: _buildModernCard(
        color: Colors.red[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Erreur lors du chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadArmoires,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
              colors: [Colors.purple[900]!, Colors.purple[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.warehouse, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Armoires',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _checkAbonnement();
              _loadArmoires();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading || !_abonnementCharge
          ? Center(
              child: _buildModernCard(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des armoires...'),
                  ],
                ),
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    if (!_abonnementActif)
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: _buildSubscriptionWarning(),
                      ),
                    Expanded(
                      child: _armoires.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: EdgeInsets.all(20),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 
                                               MediaQuery.of(context).size.width > 800 ? 3 : 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _armoires.length,
                              itemBuilder: (context, index) {
                                final armoire = _armoires[index];
                                return Stack(
                                  children: [
                                    _buildArmoireCard(armoire),
                                    if (_abonnementActif)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red[600]),
                                          tooltip: 'Supprimer l\'armoire',
                                          onPressed: () => _deleteArmoire(armoire),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abonnementActif ? _createArmoire : null,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Créer', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple[600],
        tooltip: 'Créer une armoire',
      ),
    );
  }
} 