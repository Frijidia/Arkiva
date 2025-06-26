import { Pool } from 'pg';
import { Sequelize } from 'sequelize';
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

// Configuration Sequelize
const sequelize = new Sequelize(
  process.env.POSTGRES_DB,
  process.env.POSTGRES_USER,
  process.env.POSTGRES_PASSWORD,
  {
    host: process.env.POSTGRES_HOST,
    port: parseInt(process.env.POSTGRES_PORT),
    dialect: 'postgres',
    logging: false,
    dialectOptions: {
      ssl: process.env.POSTGRES_SSL === 'true' ? {
        require: true,
        rejectUnauthorized: false
      } : false
    }
  }
);

// Test de la connexion PostgreSQL
pool.connect((err, client, release) => {
  if (err) {
    console.error('Erreur de connexion à la base de données PostgreSQL:', err.stack);
  } else {
    console.log('Connexion à la base de données PostgreSQL établie');
    release();
  }
});

// Test de la connexion Sequelize - COMMENTÉ POUR ÉVITER LA BOUCLE INFINIE
// sequelize.authenticate()
//   .then(() => {
//     console.log('Connexion à la base de données Sequelize établie');
//   })
//   .catch(err => {
//     console.error('Erreur de connexion à la base de données Sequelize:', err);
//   });

// Gestionnaire d'erreurs
pool.on('error', (err) => {
  console.error('Erreur inattendue sur le client de la base de données', err);
});

export default {
  query: (text, params) => pool.query(text, params),
  pool,
  sequelize
};