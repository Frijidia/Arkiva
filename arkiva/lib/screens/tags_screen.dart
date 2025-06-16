import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tag_service.dart';
import '../services/auth_state_service.dart';
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
          title: const Text('Créer un tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
              Row(
                children: [
                  const Text('Couleur : '),
                  GestureDetector(
                    onTap: () async {
                      Color? picked = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choisir une couleur'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: selectedColor,
                              onColorChanged: (color) => setState(() => selectedColor = color),
                              showLabel: false,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () => Navigator.of(context).pop(selectedColor),
                            ),
                          ],
                        ),
                      );
                      if (picked != null) setState(() => selectedColor = picked);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
                ],
              ),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
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
        title: const Text('Renommer le tag'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nouveau nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Renommer')),
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteTag(int tagId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tag'),
        content: const Text('Voulez-vous vraiment supprimer ce tag ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
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
          title: const Text('Suggestions de tags'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((s) => ListTile(title: Text(s))).toList(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des tags'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTags),
          IconButton(icon: const Icon(Icons.lightbulb), onPressed: _showSuggestions),
          IconButton(icon: const Icon(Icons.add), onPressed: _createTag),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _tags.length,
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _parseColor(tag['color']),
                      ),
                      title: Text(tag['name']),
                      subtitle: Text(tag['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _renameTag(tag['tag_id'], tag['name'])),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTag(tag['tag_id'])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 