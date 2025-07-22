import pool from '../../config/database.js';

// Création de la table journal_activite
const createAuditTable = `
  CREATE TABLE IF NOT EXISTS journal_activite (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    action VARCHAR(50) NOT NULL,
    type_cible VARCHAR(50) NOT NULL,
    id_cible INTEGER,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

// Exécution de la création de la table
pool.query(createAuditTable)
  .then(() => {
    console.log('Table journal_activite created successfully');
  })
  .catch((err) => console.error('Error setting up journal_activite table:', err)); 