import 'package:flutter/material.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  // Filtres avancés
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;
  String? _selectedTag;
  DateTimeRange? _selectedDateRange;

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    try {
      List<dynamic> results = [];
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        // Recherche par tag
        results = await _searchService.getFilesByTag(token, int.parse(_selectedTag!), entrepriseId);
      } else if (_selectedDateRange != null) {
        // Recherche par date
        final debut = _selectedDateRange!.start.toIso8601String().substring(0, 10);
        final fin = _selectedDateRange!.end.toIso8601String().substring(0, 10);
        results = await _searchService.searchByDate(token, debut, fin, entrepriseId);
      } else if (_selectedArmoire != null || _selectedCasier != null || _selectedDossier != null || _searchController.text.isNotEmpty) {
        // Recherche flexible
        results = await _searchService.searchFlexible(
          token,
          entrepriseId,
          armoire: _selectedArmoire,
          casier: _selectedCasier,
          dossier: _selectedDossier,
          nom: _searchController.text.isNotEmpty ? _searchController.text : null,
        );
      } else if (_searchController.text.isNotEmpty) {
        // Recherche OCR/nom
        results = await _searchService.searchByOcr(token, _searchController.text, entrepriseId);
      }
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setStateSB) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filtres avancés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Armoire'),
                  onChanged: (v) => setStateSB(() => _selectedArmoire = v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Casier'),
                  onChanged: (v) => setStateSB(() => _selectedCasier = v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Dossier'),
                  onChanged: (v) => setStateSB(() => _selectedDossier = v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Tag (ID)'),
                  onChanged: (v) => setStateSB(() => _selectedTag = v),
                ),
                Row(
                  children: [
                    const Text('Date : '),
                    Text(_selectedDateRange == null ? 'Non sélectionnée' :
                      '${_selectedDateRange!.start.toString().substring(0,10)} - ${_selectedDateRange!.end.toString().substring(0,10)}'),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setStateSB(() => _selectedDateRange = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setStateSB(() {
                          _selectedArmoire = null;
                          _selectedCasier = null;
                          _selectedDossier = null;
                          _selectedTag = null;
                          _selectedDateRange = null;
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearch();
                      },
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openFilters,
            tooltip: 'Filtres avancés',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Recherche OCR, nom, ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty)
            const Center(child: Text('Aucun résultat'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final file = _results[index];
                  return Card(
                    child: ListTile(
                      title: Text(file['nom'] ?? file['name'] ?? 'Document'),
                      subtitle: Text(file['chemin'] ?? ''),
                      trailing: Icon(Icons.description),
                      // Ajoute d'autres infos ou actions ici
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 