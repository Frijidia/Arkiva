GET http://localhost:3000/api/stats/entreprise/:id                    # Stats générales
GET http://localhost:3000/api/stats/entreprise/:id/admins             # Liste admins
GET http://localhost:3000/api/stats/entreprise/:id/contributeurs      # Liste contributeurs  
GET http://localhost:3000/api/stats/entreprise/:id/lecteurs           # Liste lecteurs
GET http://localhost:3000/api/stats/entreprise/:id/armoires           # Stats armoires
GET http://localhost:3000/api/stats/entreprise/:id/activite           # Activité récente
GET http://localhost:3000/api/stats/entreprise/:id/types-fichiers     # Par type de fichier
GET http://localhost:3000/api/stats/entreprise/:id/croissance         # Croissance mensuelle
GET http://localhost:3000/api/stats/entreprise/:id/tableau-bord       # Tableau de bord complet
GET http://localhost:3000/api/stats/entreprise/:id/logs               # Tous les logs avec pagination
GET http://localhost:3000/api/stats/entreprise/:id/logs/stats         # Statistiques des logs
GET http://localhost:3000/api/stats/entreprise/:id/logs/utilisateurs  # Top 20 utilisateurs les plus actifs
GET http://localhost:3000/api/stats/entreprise/:id/logs/actions       # Logs des actions avec logs
GET http://localhost:3000/api/stats/entreprise/:id/logs/cibles    
GET http://localhost:3000/api/stats/entreprise/:id/tableau-bord-complet # Tableau de bord complet avec logs
GET http://localhost:3000/api/stats/globales                          # Stats globales (admin)
