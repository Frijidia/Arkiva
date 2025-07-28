import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/screens/dossiers_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/services/casier_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/responsive_service.dart';
import 'package:arkiva/widgets/deplacement_dialog.dart';
import 'package:provider/provider.dart';

class CasiersScreen extends StatefulWidget {
  final int armoireId;
  final String armoireNom;
  final int entrepriseId;

  const CasiersScreen({
    super.key,
    required this.armoireId,
    required this.armoireNom,
    required this.entrepriseId,
  });

  @override
  State<CasiersScreen> createState() => _CasiersScreenState();
}

class _CasiersScreenState extends State<CasiersScreen> {
  final CasierService _casierService = CasierService();
  List<Casier> _casiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCasiers();
  }

  Future<void> _loadCasiers() async {
    setState(() => _isLoading = true);
    try {
      final casiers = await _casierService.getCasiersByArmoire(widget.armoireId);
      setState(() {
        _casiers = casiers;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildModernCard({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
              color?.withOpacity(0.05) ?? Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.blue[600],
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: child,
    );
  }

  Future<void> _renommerCasier(Casier casier) async {
    final TextEditingController nomController = TextEditingController(text: casier.nom);
    final TextEditingController descriptionController = TextEditingController(text: casier.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Renommer le casier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernTextField(
              controller: nomController,
              label: 'Nom du casier',
              hint: 'Ex: Casier 1',
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Description du casier',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          _buildModernButton(
            onPressed: () {
              if (nomController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'nom': nomController.text,
                  'description': descriptionController.text,
                });
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedCasier = await _casierService.renameCasier(casier.casierId, result['description'] ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sous-titre du casier mis à jour avec succès')),
        );
        await _loadCasiers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _creerCasier() async {
    final authStateService = context.read<AuthStateService>();
    final userId = authStateService.userId;

    if (userId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Informations utilisateur manquantes')),
      );
      return;
    }

    try {
       await _casierService.createCasier(
         widget.armoireId,
         int.parse(userId),
       );
       await _loadCasiers();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Casier créé avec succès')),
       );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: ${e.toString()}')),
      );
    }
  }

  Future<void> _modifierCasier(Casier casier) async {
    final TextEditingController nomController = TextEditingController(text: casier.nom);
    final TextEditingController descriptionController = TextEditingController(text: casier.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Modifier le casier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Description du casier',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          _buildModernButton(
            onPressed: () {
              Navigator.pop(context, {
                'description': descriptionController.text,
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _casierService.renameCasier(casier.casierId, result['description'] ?? '');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _supprimerCasier(Casier casier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Supprimer le casier'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce casier ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          _buildModernButton(
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red[600],
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _casierService.deleteCasier(casier.casierId);
        await _loadCasiers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Casier supprimé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deplacerCasier(Casier casier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DeplacementDialog(typeElement: 'casier'),
    );

    if (result != null) {
      try {
        await _casierService.deplacerCasier(casier.casierId, result['armoire_id']);
        await _loadCasiers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Casier déplacé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du déplacement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.folder, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.armoireNom,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: () {
              print('Téléverser button pressed');
              // TODO: Naviguer vers l'écran de téléversement
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner, color: Colors.white),
            onPressed: () {
              print('Scanner button pressed');
              // TODO: Naviguer vers l'écran de scan
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _creerCasier,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[50]!, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadCasiers,
          child: _casiers.isEmpty
              ? Center(
                  child: _buildModernCard(
                    color: Colors.orange,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: ResponsiveService.getIconSize(context) * 2,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun casier dans cette armoire',
                          style: TextStyle(
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre premier casier',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildModernButton(
                          onPressed: _creerCasier,
                          backgroundColor: Colors.orange[600],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add),
                              const SizedBox(width: 8),
                              const Text('Créer un casier'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    print('Nombre de casiers à afficher : ${_casiers.length}');
                    for (var casier in _casiers) {
                      print('Casier: ${casier.casierId} - ${casier.nom}');
                    }
                    return GridView.builder(
                      padding: ResponsiveService.getScreenPadding(context),
                      gridDelegate: ResponsiveService.getResponsiveGridDelegate(context),
                      itemCount: _casiers.length,
                      itemBuilder: (context, index) {
                        return _buildCasierCard(_casiers[index], index);
                      },
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerCasier,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau casier'),
        tooltip: 'Créer un nouveau casier',
      ),
    );
  }

  Widget _buildCasierCard(Casier casier, int casierIndex) {
    bool isFirstCasier = casierIndex == 0;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    final color = colors[casierIndex % colors.length];
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DossiersScreen(
                casier: casier,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color[50]!,
                color[100]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(ResponsiveService.getCardPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color[600]!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFirstCasier ? Icons.folder_open : Icons.folder,
                            size: ResponsiveService.getIconSize(context),
                            color: color[700],
                          ),
                        ),
                        const Spacer(),
                        if (isFirstCasier)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRINCIPAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveService.getFontSize(context, baseSize: 10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        casier.nom,
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: isFirstCasier ? 18 : 16),
                          fontWeight: FontWeight.bold,
                          color: color[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (casier.description != null && casier.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          casier.description!,
                          style: TextStyle(
                            color: color[600],
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: ResponsiveService.getIconSize(context), color: color[600]),
                            tooltip: 'Modifier le casier',
                            onPressed: () => _modifierCasier(casier),
                          ),
                          IconButton(
                            icon: Icon(Icons.move_to_inbox, size: ResponsiveService.getIconSize(context), color: color[600]),
                            tooltip: 'Déplacer le casier',
                            onPressed: () => _deplacerCasier(casier),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: ResponsiveService.getIconSize(context), color: Colors.red[600]),
                            tooltip: 'Supprimer le casier',
                            onPressed: () => _supprimerCasier(casier),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 