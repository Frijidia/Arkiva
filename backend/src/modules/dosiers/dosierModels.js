import pool from '../../config/database.js';

const createTabledosier = `
 CREATE TABLE IF NOT EXISTS dossiers (
  dossier_id SERIAL PRIMARY KEY,
  cassier_id INTEGER REFERENCES casiers(cassier_id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  nom VARCHAR(100),
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version_id INTEGER DEFAULT 0
);
`;

pool.query(createTabledosier)
    .then(() => console.log('Table dosier created successfully'))
    .catch((err) => console.error('Error creating table:', err));

