import pool from '../../config/database.js';

const createTableQuery = `
  CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    username VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    armoire_limit INTEGER DEFAULT 2,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

pool.query(createTableQuery)
  .then(() => {
    console.log('Table users created successfully');
  })
  .catch((err) => console.error('Error setting up users table:', err));
