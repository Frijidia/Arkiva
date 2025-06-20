import pool from '../../config/database.js';

const createTableSubscriptions = `
 CREATE TABLE IF NOT EXISTS subscription (
  suscription_id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  prix VARCHAR(255) NOT NULL,
  duree INTEGER NOT NULL, -- durée en mois
  description TEXT,
  status VARCHAR(50) DEFAULT 'actif', -- actif, inactif, suspendu
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
 );
`;

const createTablePayments = `
 CREATE TABLE IF NOT EXISTS payments (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  suscription_id INTEGER REFERENCES suscription(suscription_id) ON DELETE CASCADE,
  montant DECIMAL(10, 2) NOT NULL,
  statut VARCHAR(50) NOT NULL, -- succès, échec, en attente
  date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reference_transaction VARCHAR(255) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
 );
`;

const initializeTable = async () => {
  try {
    await pool.query(createTableSubscriptions);
    console.log('✅ Table suscription créée ou déjà existante');

    await pool.query(createTablePayments);
    console.log('✅ Table payments créée ou déjà existante');

  } catch (err) {
    console.error('❌ Erreur lors de l\'initialisation des tables :', err);
    throw err;
  }
};

initializeTable();

export default pool;
