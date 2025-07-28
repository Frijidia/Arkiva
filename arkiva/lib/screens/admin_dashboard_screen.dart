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

  // Widgets helpers pour un design moderne
  Widget _buildModernCard({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: padding ?? EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: color != null ? LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return _buildModernCard(
      color: color,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required String username,
    required String email,
    required String role,
    required Color roleColor,
  }) {
    return _buildModernCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.2),
            child: Icon(
              role == 'admin' ? Icons.admin_panel_settings :
              role == 'contributeur' ? Icons.edit :
              Icons.person,
              color: roleColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String action,
    required String element,
    required String user,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return _buildModernCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$action : $element',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Par $user le $date',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Dashboard Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue générale'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.archive), text: 'Armoires'),
            Tab(icon: Icon(Icons.timeline), text: 'Activité'),
            Tab(icon: Icon(Icons.folder), text: 'Types de fichiers'),
            Tab(icon: Icon(Icons.trending_up), text: 'Croissance'),
            Tab(icon: Icon(Icons.analytics), text: 'Logs'),
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
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des statistiques...'),
                ],
              ),
            ),
          );
        }
        
        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d\'ensemble',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    title: 'Utilisateurs',
                    value: '${stats['nombre_utilisateurs']}',
                    icon: Icons.people,
                    color: Colors.blue,
                    subtitle: 'Total des utilisateurs',
                  ),
                  _buildStatCard(
                    title: 'Armoires',
                    value: '${stats['nombre_armoires']}',
                    icon: Icons.archive,
                    color: Colors.green,
                    subtitle: 'Armoires créées',
                  ),
                  _buildStatCard(
                    title: 'Fichiers',
                    value: '${stats['nombre_fichiers']}',
                    icon: Icons.folder,
                    color: Colors.orange,
                    subtitle: 'Documents stockés',
                  ),
                  _buildStatCard(
                    title: 'Espace',
                    value: '${stats['taille_totale_mb'] ?? 0} MB',
                    icon: Icons.storage,
                    color: Colors.purple,
                    subtitle: 'Espace utilisé',
                  ),
                ],
              ),
            ],
          ),
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
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des utilisateurs...'),
                ],
              ),
            ),
          );
        }
        
        final admins = snapshot.data![0];
        final contributeurs = snapshot.data![1];
        final lecteurs = snapshot.data![2];
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des utilisateurs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              
              // Admins
              if (admins.isNotEmpty) ...[
                _buildModernCard(
                  color: Colors.red[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.red[600]),
                          SizedBox(width: 8),
                          Text(
                            'Administrateurs (${admins.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...admins.map((admin) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildUserCard(
                          username: admin['username'],
                          email: admin['email'],
                          role: 'admin',
                          roleColor: Colors.red[600]!,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Contributeurs
              if (contributeurs.isNotEmpty) ...[
                _buildModernCard(
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            'Contributeurs (${contributeurs.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...contributeurs.map((c) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildUserCard(
                          username: c['username'],
                          email: c['email'],
                          role: 'contributeur',
                          roleColor: Colors.blue[600]!,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Lecteurs
              if (lecteurs.isNotEmpty) ...[
                _buildModernCard(
                  color: Colors.green[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green[600]),
                          SizedBox(width: 8),
                          Text(
                            'Lecteurs (${lecteurs.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...lecteurs.map((l) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildUserCard(
                          username: l['username'],
                          email: l['email'],
                          role: 'lecteur',
                          roleColor: Colors.green[600]!,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildArmoires() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getStatsArmoires(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des armoires...'),
                ],
              ),
            ),
          );
        }
        
        final armoires = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques par armoire',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ...armoires.map((a) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.archive, color: Colors.orange[600]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a['nom_armoire'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${a['taille_totale_mb']} MB',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Casiers',
                              value: '${a['nombre_casiers']}',
                              icon: Icons.folder,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Dossiers',
                              value: '${a['nombre_dossiers']}',
                              icon: Icons.folder_open,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Fichiers',
                              value: '${a['nombre_fichiers']}',
                              icon: Icons.insert_drive_file,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivite() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getActiviteRecente(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de l\'activité...'),
                ],
              ),
            ),
          );
        }
        
        final activites = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ...activites.map((a) {
                IconData icon;
                Color color;
                
                switch (a['type_activite']) {
                  case 'création':
                    icon = Icons.add_circle;
                    color = Colors.green;
                    break;
                  case 'modification':
                    icon = Icons.edit;
                    color = Colors.blue;
                    break;
                  case 'suppression':
                    icon = Icons.delete;
                    color = Colors.red;
                    break;
                  default:
                    icon = Icons.info;
                    color = Colors.grey;
                }
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildActivityCard(
                    action: a['type_activite'],
                    element: a['nom_element'],
                    user: a['nom_utilisateur'],
                    date: a['date_activite'],
                    icon: icon,
                    color: color,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypesFichiers() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getStatsTypesFichiers(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des types de fichiers...'),
                ],
              ),
            ),
          );
        }
        
        final types = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Répartition par type de fichier',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ...types.map((t) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildModernCard(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.insert_drive_file, color: Colors.indigo[600]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['type_fichier'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${t['nombre_fichiers']} fichiers',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${t['taille_totale_mb']} MB',
                          style: TextStyle(
                            color: Colors.indigo[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCroissance() {
    return FutureBuilder<List<dynamic>>(
      future: _statsService.getCroissance(entrepriseId, token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: _buildModernCard(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de la croissance...'),
                ],
              ),
            ),
          );
        }
        
        final croissance = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Croissance mensuelle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ...croissance.map((c) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildModernCard(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.trending_up, color: Colors.teal[600]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c['mois_formate'] ?? c['mois']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${c['nouveaux_fichiers']} nouveaux fichiers',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${c['taille_ajoutee_mb']} MB',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogs() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics et Logs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          
          // Statistiques des logs
          FutureBuilder<Map<String, dynamic>>(
            future: _statsService.getLogsStats(entrepriseId, token),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildModernCard(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des statistiques...'),
                    ],
                  ),
                );
              }
              
              final stats = snapshot.data!;
              return _buildModernCard(
                color: Colors.blue[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'Statistiques des logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total logs',
                            value: '${stats['nombre_total_logs']}',
                            icon: Icons.list,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Utilisateurs actifs',
                            value: '${stats['nombre_utilisateurs_actifs']}',
                            icon: Icons.people,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Connexions',
                            value: '${stats['nombre_connexions']}',
                            icon: Icons.login,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          
          // Top utilisateurs actifs
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogsParUtilisateur(entrepriseId, token, limit: 20),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildModernCard(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des utilisateurs actifs...'),
                    ],
                  ),
                );
              }
              
              final users = snapshot.data!;
              return _buildModernCard(
                color: Colors.green[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.green[600]),
                        SizedBox(width: 8),
                        Text(
                          'Top utilisateurs actifs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...users.map((u) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(
                              u['username'][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['username'],
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  u['email'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${u['nombre_actions']} actions',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          
          // Logs par action
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogsParAction(entrepriseId, token),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildModernCard(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des actions...'),
                    ],
                  ),
                );
              }
              
              final actions = snapshot.data!;
              return _buildModernCard(
                color: Colors.orange[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text(
                          'Logs par action',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...actions.map((a) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.orange[600]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a['action'],
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${a['nombre_actions']} actions',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          
          // Tous les logs (pagination)
          FutureBuilder<List<dynamic>>(
            future: _statsService.getLogs(entrepriseId, token, limit: _logsPageSize, offset: _logsPage * _logsPageSize),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildModernCard(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des logs...'),
                    ],
                  ),
                );
              }
              
              final logs = snapshot.data!;
              return _buildModernCard(
                color: Colors.purple[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.purple[600]),
                        SizedBox(width: 8),
                        Text(
                          'Tous les logs (pagination)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...logs.map((log) {
                      final details = log['details'] ?? {};
                      final hasHumanMessage = details['message'] != null;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildModernCard(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details['message'] ?? '${log['action']} sur ${log['type_cible']}',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (!hasHumanMessage) ...[
                                SizedBox(height: 4),
                                Text(
                                  'Par ${log['username'] ?? log['user_id']} le ${log['created_at']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (log['action'] == 'delete' && log['type_cible'] == 'file' ||
                                  log['action'] == 'update' && log['type_cible'] == 'file') ...[
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (log['action'] == 'delete' && log['type_cible'] == 'file')
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: restaurer le fichier
                                        },
                                        icon: Icon(Icons.restore, size: 16),
                                        label: Text('Restaurer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    if (log['action'] == 'update' && log['type_cible'] == 'file') ...[
                                      SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: afficher les versions
                                        },
                                        icon: Icon(Icons.history, size: 16),
                                        label: Text('Versions'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[600],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    // Pagination
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: _logsPage > 0 ? () => setState(() => _logsPage--) : null,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Page ${_logsPage + 1}',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () => setState(() => _logsPage++),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 