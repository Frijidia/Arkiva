import pool from '../../config/database.js';

  const createTableTags = `
    CREATE TABLE IF NOT EXISTS tags (
      tag_id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      color VARCHAR(7) NOT NULL,
      description TEXT
    );
  `;

  const createTablefichierTags = `
    CREATE TABLE IF NOT EXISTS fichier_tags (
      fichier_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      PRIMARY KEY (fichier_id, tag_id),
      FOREIGN KEY (fichier_id) REFERENCES fichiers(fichier_id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
    );
  `;

  // On exécute la première requête, puis la deuxième
  pool.query(createTableTags)
    .then(() => {
      console.log('Table tags created successfully');
      return pool.query(createTablefichierTags);
    })
    .then(() => console.log('Table fichier_tags created successfully'))
    .catch((err) => console.error('Error creating tables:', err));
