import { Pool } from 'pg';
import "./config.js"
// Configuration de la base de données

const pool = new Pool({
  user: process.env.POSTGRES_USER ,
  host: process.env.POSTGRES_HOST ,
  database: process.env.POSTGRES_DB ,
  password: process.env.POSTGRES_PASSWORD ,
  port: parseInt(process.env.POSTGRES_PORT) ,
  ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: parseInt(process.env.MAX_POOL_SIZE) || 20,
  min: parseInt(process.env.MIN_POOL_SIZE) || 5,
  idleTimeoutMillis: parseInt(process.env.IDLE_TIMEOUT_MS) || 30000,
  connectionTimeoutMillis: parseInt(process.env.CONNECTION_TIMEOUT_MS) || 10000
});

// Test de la connexion
pool.connect((err, client, release) => {
  if (err) {
    console.error('Erreur de connexion à la base de données:', err.stack);
  } else {
    console.log('Connexion à la base de données établie');
    release();
  }
});

// Gestionnaire d'erreurs
pool.on('error', (err) => {
  console.error('Erreur inattendue sur le client de la base de données', err);
});

export default {
  query: (text, params) => pool.query(text, params),
  pool,
};