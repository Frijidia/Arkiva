import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tag_service.dart';
import '../services/auth_state_service.dart';
import '../services/responsive_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final TagService _tagService = TagService();
  List<dynamic> _tags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
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

  Future<void> _loadTags() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      final tags = await _tagService.getAllTags(token!, entrepriseId!);
      setState(() { _tags = tags; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return Colors.grey;
    try {
      if (colorString.startsWith('#') && (colorString.length == 7)) {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      }
    } catch (_) {}
    return Colors.grey;
  }

  Future<void> _createTag() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = Colors.blue; // couleur par défaut
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.label, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Créer un tag'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernTextField(
                controller: nameController,
                label: 'Nom du tag',
                hint: 'Entrez le nom du tag',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Couleur : ', style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Color? picked = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              Icon(Icons.palette, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              const Text('Choisir une couleur'),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: selectedColor,
                              onColorChanged: (color) => setState(() => selectedColor = color),
                              showLabel: false,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Annuler'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            _buildModernButton(
                              onPressed: () => Navigator.of(context).pop(selectedColor),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (picked != null) setState(() => selectedColor = picked);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: descriptionController,
                label: 'Description',
                hint: 'Description du tag (facultatif)',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            _buildModernButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final hexColor = '#${selectedColor.value.toRadixString(16).substring(2)}';
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'color': hexColor,
                    'description': descriptionController.text
                  });
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result['name'] != null && result['name']!.isNotEmpty) {
      try {
        final authState = context.read<AuthStateService>();
        final token = authState.token;
        final entrepriseId = authState.entrepriseId;
        await _tagService.createTag(token!, entrepriseId!, result['name']!, result['color']!, result['description'] ?? '');
        await _loadTags();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "${result['name']}" créé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _renameTag(int tagId, String oldName) async {
    final controller = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Renommer le tag'),
          ],
        ),
        content: _buildModernTextField(
          controller: controller,
          label: 'Nouveau nom',
          hint: 'Entrez le nouveau nom',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          _buildModernButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != oldName) {
      try {
        final authState = context.read<AuthStateService>();
        final token = authState.token;
        final entrepriseId = authState.entrepriseId;
        await _tagService.renameTag(token!, entrepriseId!, tagId, result);
        await _loadTags();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag renommé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteTag(int tagId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Supprimer le tag'),
          ],
        ),
        content: const Text('Voulez-vous vraiment supprimer ce tag ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
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
        final authState = context.read<AuthStateService>();
        final token = authState.token;
        final entrepriseId = authState.entrepriseId;
        await _tagService.deleteTag(token!, entrepriseId!, tagId);
        await _loadTags();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag supprimé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _showSuggestions() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      final suggestions = await _tagService.getPopularTags(token!, entrepriseId!);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600]),
              const SizedBox(width: 8),
              const Text('Suggestions de tags'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((s) => ListTile(
              leading: Icon(Icons.label, color: Colors.blue[600]),
              title: Text(s),
            )).toList(),
          ),
          actions: [
            _buildModernButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
            Icon(Icons.label, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Gestion des tags',
              style: TextStyle(
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTags,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb, color: Colors.white),
            onPressed: _showSuggestions,
            tooltip: 'Suggestions',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createTag,
            tooltip: 'Créer un tag',
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
        child: _error != null
            ? Center(
                child: _buildModernCard(
                  color: Colors.red,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: ResponsiveService.getIconSize(context) * 2,
                        color: Colors.red[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildModernButton(
                        onPressed: _loadTags,
                        backgroundColor: Colors.red[600],
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : _tags.isEmpty
                ? Center(
                    child: _buildModernCard(
                      color: Colors.blue,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label,
                            size: ResponsiveService.getIconSize(context) * 2,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun tag créé',
                            style: TextStyle(
                              fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez votre premier tag',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _buildModernButton(
                            onPressed: _createTag,
                            backgroundColor: Colors.blue[600],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add),
                                const SizedBox(width: 8),
                                const Text('Créer un tag'),
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
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      return _buildTagCard(tag, index);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTag,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau tag'),
        tooltip: 'Créer un nouveau tag',
      ),
    );
  }

  Widget _buildTagCard(dynamic tag, int tagIndex) {
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
    final color = colors[tagIndex % colors.length];
    final tagColor = _parseColor(tag['color']);
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Optionnel : afficher les détails du tag
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
                            color: tagColor?.withOpacity(0.2) ?? color[600]!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.label,
                            size: ResponsiveService.getIconSize(context),
                            color: tagColor ?? color[700],
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
                            'TAG',
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
                        tag['name'] ?? '',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                          color: color[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tag['description'] != null && tag['description'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          tag['description'],
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
                        color: tagColor ?? color[300],
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: ResponsiveService.getIconSize(context),
                          color: color[600],
                        ),
                        tooltip: 'Modifier le tag',
                        onPressed: () => _renameTag(tag['tag_id'], tag['name']),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: ResponsiveService.getIconSize(context),
                          color: Colors.red[600],
                        ),
                        tooltip: 'Supprimer le tag',
                        onPressed: () => _deleteTag(tag['tag_id']),
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