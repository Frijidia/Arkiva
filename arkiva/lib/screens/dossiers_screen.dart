import 'package:flutter/material.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/dossier_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/responsive_service.dart';
import 'package:arkiva/widgets/deplacement_dialog.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/fichiers_screen.dart';

class DossiersScreen extends StatefulWidget {
  final Casier casier;

  const DossiersScreen({super.key, required this.casier});

  @override
  State<DossiersScreen> createState() => _DossiersScreenState();
}

class _DossiersScreenState extends State<DossiersScreen> {
  final DossierService _dossierService = DossierService();
  List<Dossier> _dossiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDossiers();
  }

  Future<void> _loadDossiers() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final dossiers = await _dossierService.getDossiers(token, widget.casier.casierId);
        setState(() {
          _dossiers = dossiers;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
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

  Future<void> _creerDossier() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.create_new_folder, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Nouveau dossier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernTextField(
              controller: nomController,
              label: 'Nom du dossier',
              hint: 'Ex: Dossier 1',
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Description du dossier',
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;
        final userId = authStateService.userId;

        if (token != null && userId != null) {
          await _dossierService.createDossier(
            token,
            widget.casier.casierId,
            result['nom']!,
            result['description'] ?? '',
            int.parse(userId),
          );
          await _loadDossiers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier créé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _renommerDossier(Dossier dossier) async {
    final TextEditingController nomController = TextEditingController(text: dossier.nom);
    final TextEditingController descriptionController = TextEditingController(text: dossier.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Renommer le dossier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernTextField(
              controller: nomController,
              label: 'Nouveau nom',
              hint: 'Entrez le nouveau nom',
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Description du dossier',
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
        final token = context.read<AuthStateService>().token;
        if (token != null) {
          await _dossierService.updateDossier(
            token,
            dossier.dossierId,
            result['nom']!,
            result['description'] ?? '',
          );
          await _loadDossiers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier mis à jour avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _supprimerDossier(Dossier dossier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Text('Voulez-vous vraiment supprimer le dossier "${dossier.nom}" ?'),
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
        final token = context.read<AuthStateService>().token;
        if (token != null) {
          await _dossierService.deleteDossier(token, dossier.dossierId);
          await _loadDossiers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier supprimé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deplacerDossier(Dossier dossier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DeplacementDialog(typeElement: 'dossier'),
    );

    if (result != null) {
      try {
        final token = context.read<AuthStateService>().token;
        if (token != null) {
          await _dossierService.deplacerDossier(token, dossier.dossierId!, result['cassier_id']);
          await _loadDossiers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier déplacé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du déplacement: $e')),
        );
      }
    }
  }

  void _naviguerVersDocuments(Dossier dossier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FichiersScreen(dossier: dossier),
      ),
    );
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
              widget.casier.nom,
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _creerDossier,
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
          onRefresh: _loadDossiers,
          child: _dossiers.isEmpty
              ? Center(
                  child: _buildModernCard(
                    color: Colors.green,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: ResponsiveService.getIconSize(context) * 2,
                          color: Colors.green[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun dossier dans ce casier',
                          style: TextStyle(
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre premier dossier',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildModernButton(
                          onPressed: _creerDossier,
                          backgroundColor: Colors.green[600],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add),
                              const SizedBox(width: 8),
                              const Text('Créer un dossier'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: ResponsiveService.getScreenPadding(context),
                  gridDelegate: ResponsiveService.getResponsiveGridDelegate(context),
                  itemCount: _dossiers.length,
                  itemBuilder: (context, index) {
                    return _buildDossierCard(_dossiers[index], index);
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerDossier,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dossier'),
        tooltip: 'Créer un nouveau dossier',
      ),
    );
  }

  Widget _buildDossierCard(Dossier dossier, int dossierIndex) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    final color = colors[dossierIndex % colors.length];
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _naviguerVersDocuments(dossier),
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
                            Icons.folder,
                            size: ResponsiveService.getIconSize(context),
                            color: color[700],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DOSSIER',
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
                        dossier.nom,
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                          color: color[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dossier.description != null && dossier.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          dossier.description!,
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
                child: Container(
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
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: ResponsiveService.getIconSize(context),
                      color: color[600],
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'renommer':
                          _renommerDossier(dossier);
                          break;
                        case 'deplacer':
                          _deplacerDossier(dossier);
                          break;
                        case 'supprimer':
                          _supprimerDossier(dossier);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'renommer',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: ResponsiveService.getIconSize(context), color: color[600]),
                            const SizedBox(width: 8),
                            const Text('Renommer'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deplacer',
                        child: Row(
                          children: [
                            Icon(Icons.move_to_inbox, size: ResponsiveService.getIconSize(context), color: color[600]),
                            const SizedBox(width: 8),
                            const Text('Déplacer'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'supprimer',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: ResponsiveService.getIconSize(context), color: Colors.red[600]),
                            const SizedBox(width: 8),
                            const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}