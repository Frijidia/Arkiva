import 'package:flutter/material.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/models/document.dart'; // Import pour le modèle Document
import 'package:arkiva/screens/fichiers_screen.dart';
import 'package:arkiva/services/animation_service.dart'; // Import pour les animations si nécessaire

class DossiersScreen extends StatefulWidget {
  final Casier casier;

  const DossiersScreen({super.key, required this.casier});

  @override
  State<DossiersScreen> createState() => _DossiersScreenState();
}

class _DossiersScreenState extends State<DossiersScreen> {
  late List<Dossier> _dossiers;
  List<Dossier> _filteredDossiers = [];
  bool _isLoading = false; // Initialisation à false car on charge depuis les données de test

  final TextEditingController _searchController = TextEditingController(); // Contrôleur pour la recherche

  @override
  void initState() {
    super.initState();
    _loadDossiers(); // Charger les dossiers dès l'initialisation
  }

  @override
  void dispose() {
    _searchController.dispose(); // Libérer le contrôleur
    super.dispose();
  }

  void _loadDossiers() {
    // TODO: Charger les dossiers depuis le backend (maintenant les casiers contiennent des dossiers)
    // Pour l'instant, on utilise les dossiers du casier passé en paramètre
    setState(() {
      _dossiers = widget.casier.dossiers; // Charger depuis le casier parent
      _filteredDossiers = _dossiers; // Initialiser la liste filtrée
      _isLoading = false;
    });
  }

  void _filterDossiers(String query) {
    setState(() {
      _filteredDossiers = _dossiers
          .where((dossier) =>
              dossier.nom.toLowerCase().contains(query.toLowerCase()) ||
              (dossier.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _ajouterDossier() {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du dossier',
                hintText: 'Entrez le nom du dossier',
              ),
              autofocus: true, // Focus automatique sur ce champ
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Entrez la description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la création réelle dans le backend plus tard
              final nom = nomController.text.trim(); // Utiliser trim() pour retirer les espaces blancs
              final description = descriptionController.text.trim();

              if (nom.isNotEmpty) {
                final nouveauDossier = Dossier(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), // Générer un ID unique temporaire
                  nom: nom,
                  casierId: widget.casier.id, // Assigner l'ID du casier parent
                  description: description.isNotEmpty ? description : null, // Mettre null si description est vide
                  dateCreation: DateTime.now(),
                  dateModification: DateTime.now(),
                  documents: [], // Un nouveau dossier est vide au début
                );

                setState(() {
                  _dossiers.add(nouveauDossier);
                  _filterDossiers(_searchController.text); // Filtrer à nouveau après ajout
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _modifierDossier(Dossier dossier) {
    final TextEditingController nomController = TextEditingController(text: dossier.nom);
    final TextEditingController descriptionController = TextEditingController(text: dossier.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du dossier',
                hintText: 'Entrez le nouveau nom',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Entrez la nouvelle description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la modification réelle dans le backend plus tard
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isNotEmpty) {
                setState(() {
                  final index = _dossiers.indexWhere((d) => d.id == dossier.id);
                  if (index != -1) {
                    _dossiers[index] = Dossier(
                      id: dossier.id,
                      nom: nom,
                      casierId: dossier.casierId,
                      description: description.isNotEmpty ? description : null,
                      dateCreation: dossier.dateCreation,
                      dateModification: DateTime.now(), // Mettre à jour la date de modification
                      documents: dossier.documents,
                    );
                    _filterDossiers(_searchController.text); // Filtrer à nouveau après modification
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _supprimerDossier(Dossier dossier) {
    // TODO: Implémenter la suppression de dossier
    print('Supprimer dossier: ${dossier.nom}');
  }

  Widget _buildAddDossierCard() { // Méthode pour construire la carte d'ajout de dossier
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _ajouterDossier, // Appeler la méthode pour ajouter un dossier
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Nouveau dossier', // Changer le texte
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierCard(Dossier dossier, int dossierIndex) { // Méthode pour construire la carte de dossier
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('Clic sur le dossier: ${dossier.nom}'); // Changer le texte de débogage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FichiersScreen(dossier: dossier),
            ),
          );
        },
        onLongPress: () => _modifierDossier(dossier), // Utiliser la méthode pour modifier un dossier
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16), // Padding ajusté
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.folder, size: 32, color: Colors.blue[700]), // Icône de dossier standard
                  const SizedBox(height: 12), // Espacement ajusté
                  Expanded(
                    child: Text(
                      dossier.nom, // Afficher le nom réel du dossier
                      style: TextStyle(
                        fontSize: 18, // Taille de police ajustée
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dossier.description != null && dossier.description!.isNotEmpty) ...[
                    const SizedBox(height: 4), // Espacement ajusté
                    Expanded(
                      child: Text(
                        dossier.description!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(), // Permet d'aligner le texte en bas
                  Text(
                    '${dossier.documents.length} fichiers', // Afficher le nombre de fichiers
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'modifier':
                      _modifierDossier(dossier); // Utiliser la méthode pour modifier un dossier
                      break;
                    case 'supprimer':
                      _supprimerDossier(dossier); // Utiliser la méthode pour supprimer un dossier
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'modifier',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
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
        title: Text('Dossiers de ${widget.casier.nom}'), // Afficher le nom du casier parent dans la barre de titre
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DossierSearchDelegate(
                  _dossiers, // Passer la liste complète pour la recherche
                  (query) {
                    _filterDossiers(query); // Utiliser la méthode de filtrage
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column( // Utiliser Column pour inclure la barre de recherche
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un dossier...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterDossiers(''); // Afficher tous les dossiers après effacement
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterDossiers, // Filtrer lors de la saisie
                  ),
                ),
                Expanded(
                  child: _filteredDossiers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Aucun dossier dans ce casier'
                                    : 'Aucun résultat trouvé',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchController.text.isEmpty) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _ajouterDossier,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Créer un dossier'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 dossiers par ligne
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredDossiers.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _filteredDossiers.length) {
                              return _buildAddDossierCard();
                            }
                            return _buildDossierCard(_filteredDossiers[index], index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _filteredDossiers.isNotEmpty // Afficher le FAB seulement si il y a des dossiers
          ? FloatingActionButton(
              onPressed: _ajouterDossier,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// TODO: Implémenter la recherche réelle si nécessaire
class DossierSearchDelegate extends SearchDelegate<Dossier?> {
  final List<Dossier> dossiers;
  final Function(String) onSearch;

  DossierSearchDelegate(this.dossiers, this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query); // Appliquer le filtre lors de la soumission
    // Les résultats sont déjà filtrés dans l'écran principal via onSearch
    return Container(); // Retourner un conteneur vide car l'écran principal gère l'affichage
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? dossiers
        : dossiers.where((dossier) =>
            dossier.nom.toLowerCase().contains(query.toLowerCase()) ||
            (dossier.description?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final dossier = suggestionList[index];
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(dossier.nom),
          subtitle: dossier.description != null && dossier.description!.isNotEmpty
              ? Text(dossier.description!)
              : null,
          onTap: () {
            query = dossier.nom;
            showResults(context); // Afficher les résultats basés sur la suggestion sélectionnée
          },
        );
      },
    );
  }
}