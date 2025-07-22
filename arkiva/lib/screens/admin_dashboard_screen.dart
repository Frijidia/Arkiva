import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/stats_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StatsService _statsService;
  late int entrepriseId;
  late String token;
  int _logsPage = 0;
  final int _logsPageSize = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final authState = Provider.of<AuthStateService>(context, listen: false);
    entrepriseId = authState.entrepriseId!;
    token = authState.token!;
    _statsService = StatsService();
      }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord administrateur'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Vue générale'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Armoires'),
            Tab(text: 'Activité'),
            Tab(text: 'Types de fichiers'),
            Tab(text: 'Croissance'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVueGenerale(),
          _buildUtilisateurs(),
          _buildArmoires(),
          _buildActivite(),
          _buildTypesFichiers(),
          _buildCroissance(),
          _buildLogs(),
        ],
      ),
    );
  }

  Widget _buildVueGenerale() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsService.getStatsGenerales(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
            children: [
              Card(
              child: ListTile(
                title: const Text('Nombre d\'utilisateurs'),
                trailing: Text('${stats['nombre_utilisateurs']}'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Nombre d\'armoires'),
                trailing: Text('${stats['nombre_armoires']}'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Nombre de fichiers'),
                trailing: Text('${stats['nombre_fichiers']}'),
                        ),
                      ),
            // Ajoute d'autres stats si besoin
          ],
        );
      },
    );
  }

  Widget _buildUtilisateurs() {
    return FutureBuilder<List<List<dynamic>>>(
      future: Future.wait([
        _statsService.getAdmins(entrepriseId, token),
        _statsService.getContributeurs(entrepriseId, token),
        _statsService.getLecteurs(entrepriseId, token),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final admins = snapshot.data![0];
        final contributeurs = snapshot.data![1];
        final lecteurs = snapshot.data![2];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Admins', style: TextStyle(fontWeight: FontWeight.bold)),
            ...admins.map((admin) => ListTile(
              title: Text(admin['username']),
              subtitle: Text(admin['email']),
              trailing: const Text('Admin'),
            )),
            const SizedBox(height: 16),
            const Text('Contributeurs', style: TextStyle(fontWeight: FontWeight.bold)),
            ...contributeurs.map((c) => ListTile(
              title: Text(c['username']),
              subtitle: Text(c['email']),
              trailing: const Text('Contributeur'),
            )),
              const SizedBox(height: 16),
            const Text('Lecteurs', style: TextStyle(fontWeight: FontWeight.bold)),
            ...lecteurs.map((l) => ListTile(
              title: Text(l['username']),
              subtitle: Text(l['email']),
              trailing: const Text('Lecteur'),
            )),
          ],
        );
      },
    );
  }

  Widget _buildArmoires() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getStatsArmoires(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final armoires = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Statistiques par armoire', style: TextStyle(fontWeight: FontWeight.bold)),
            ...armoires.map((a) => Card(
                      child: ListTile(
                title: Text(a['nom_armoire']),
                subtitle: Text('Casiers: ${a['nombre_casiers']} | Dossiers: ${a['nombre_dossiers']} | Fichiers: ${a['nombre_fichiers']}'),
                trailing: Text('${a['taille_totale_mb']} MB'),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildActivite() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getActiviteRecente(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final activites = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
                          children: [
            const Text('Activité récente', style: TextStyle(fontWeight: FontWeight.bold)),
            ...activites.map((a) => ListTile(
              title: Text('${a['type_activite']} : ${a['nom_element']}'),
              subtitle: Text('Par ${a['nom_utilisateur']} le ${a['date_activite']}'),
            )),
          ],
        );
                              },
    );
  }

  Widget _buildTypesFichiers() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getStatsTypesFichiers(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final types = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Répartition par type de fichier', style: TextStyle(fontWeight: FontWeight.bold)),
            ...types.map((t) => ListTile(
              title: Text(t['type_fichier']),
              subtitle: Text('Fichiers: ${t['nombre_fichiers']}'),
              trailing: Text('${t['taille_totale_mb']} MB'),
            )),
                              ],
        );
      },
    );
  }

  Widget _buildCroissance() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getCroissance(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final croissance = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Croissance mensuelle', style: TextStyle(fontWeight: FontWeight.bold)),
            ...croissance.map((c) => ListTile(
              title: Text('${c['mois_formate'] ?? c['mois']}'),
              subtitle: Text('Nouveaux fichiers: ${c['nouveaux_fichiers']}'),
              trailing: Text('${c['taille_ajoutee_mb']} MB'),
            )),
          ],
        );
      },
    );
  }

  Widget _buildLogs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistiques des logs', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<Map<String, dynamic>>(
            future: _statsService.getLogsStats(entrepriseId, token),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final stats = snapshot.data!;
              return Card(
                child: ListTile(
                  title: Text('Total logs: ${stats['nombre_total_logs']}'),
                  subtitle: Text('Utilisateurs actifs: ${stats['nombre_utilisateurs_actifs']}\nConnexions: ${stats['nombre_connexions']}'),
                                    ),
                                  );
                                },
                              ),
          const SizedBox(height: 24),
          const Text('Top utilisateurs actifs', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogsParUtilisateur(entrepriseId, token, limit: 20),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final users = snapshot.data!;
              return Column(
                children: users.map((u) => ListTile(
                  title: Text(u['username']),
                  subtitle: Text(u['email']),
                  trailing: Text('Actions: ${u['nombre_actions']}'),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Logs par action', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogsParAction(entrepriseId, token),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final actions = snapshot.data!;
              return Column(
                children: actions.map((a) => ListTile(
                  title: Text('${a['action']}'),
                  subtitle: Text('Utilisateurs: ${a['nombre_utilisateurs_uniques']}'),
                  trailing: Text('Actions: ${a['nombre_actions']}'),
                )).toList(),
                    );
                  },
                ),
          const SizedBox(height: 24),
          const Text('Logs par cible', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogsParCible(entrepriseId, token),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final cibles = snapshot.data!;
              return Column(
                children: cibles.map((c) => ListTile(
                  title: Text('${c['type_cible']}'),
                  subtitle: Text('Utilisateurs: ${c['nombre_utilisateurs_uniques']}'),
                  trailing: Text('Actions: ${c['nombre_actions']}'),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Tous les logs (pagination)', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogs(entrepriseId, token, limit: _logsPageSize, offset: _logsPage * _logsPageSize),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final logs = snapshot.data!;
              return Column(
                children: [
                  ...logs.map((log) {
                    final details = log['details'] ?? {};
                    final hasHumanMessage = details['message'] != null;
                    return Card(
                      child: ListTile(
                        title: Text(details['message'] ?? '${log['action']} sur ${log['type_cible']}'),
                        subtitle: hasHumanMessage ? null : Text('Par ${log['username'] ?? log['user_id']} le ${log['created_at']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (log['action'] == 'delete' && log['type_cible'] == 'file')
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: restaurer le fichier (à implémenter plus tard)
                                },
                                child: const Text('Restaurer'),
                              ),
                            if (log['action'] == 'update' && log['type_cible'] == 'file')
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: afficher les versions (à implémenter plus tard)
                                },
                                child: const Text('Versions'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _logsPage > 0 ? () => setState(() => _logsPage--) : null,
                      ),
                      Text('Page ${_logsPage + 1}'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => setState(() => _logsPage++),
            ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
} 