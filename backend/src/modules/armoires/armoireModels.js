import pool from '../../config/database.js';

const createTableArmoires = `
  CREATE TABLE IF NOT EXISTS armoires (
  armoire_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  sous_titre VARCHAR(255),
  nom VARCHAR(50),
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
  version_id INTEGER DEFAULT 0
);
`;

pool.query(createTableArmoires)
    .then(() => console.log('Table armoires created successfully'))
    .catch((err) => console.error('Error creating table:', err));
