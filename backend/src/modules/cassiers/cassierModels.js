import pool from '../../config/database.js';

const createTableCassiers = `
 CREATE TABLE IF NOT EXISTS casiers (
  cassier_id SERIAL PRIMARY KEY,
  armoire_id INTEGER REFERENCES armoires(armoire_id) ON DELETE CASCADE,
  nom VARCHAR(50) UNIQUE,
  sous_titre VARCHAR(255),
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version_id INTEGER DEFAULT 0
);
`;

pool.query(createTableCassiers)
    .then(() => console.log('Table casier created successfully'))
    .catch((err) => console.error('Error creating table:', err));



