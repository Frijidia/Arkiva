
import pool from '../../config/database.js';

const createTablefichier = `
 CREATE TABLE IF NOT EXISTS fichiers (
  fichier_id SERIAL PRIMARY KEY,
  dossier_id INTEGER REFERENCES dossiers(dossier_id) ON DELETE CASCADE,
  nom VARCHAR(255) NOT NULL,
  type VARCHAR(100), -- exemple : pdf, docx, txt
  chemin TEXT NOT NULL, -- chemin dans le système de fichiers ou URL
  taille INTEGER, -- taille en octets
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

pool.query(createTablefichier)
    .then(() => console.log('Table fichier created successfully'))
    .catch((err) => console.error('Error creating table:', err));



