import pool from '../../config/database.js';

const createTableFavoris = `
 CREATE TABLE IF NOT EXISTS favoris (
  user_id INTEGER NOT NULL,
  fichier_id INTEGER NOT NULL,
  entreprise_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, fichier_id, entreprise_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (fichier_id) REFERENCES fichiers(fichier_id),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(entreprise_id)
);

`;

pool.query(createTableFavoris)
    .then(() => console.log('Table favoris created successfully'))
    .catch((err) => console.error('Error creating table:', err));

