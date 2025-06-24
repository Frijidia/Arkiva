import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Configuration de dotenv
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '.env') });


import authRoutes from './modules/auth/authRoutes.js'; // Routes d'authentification (utilisateurs)
import entrepriseRoutes from './modules/entreprises/entrepriseRoutes.js'; // entreprises
import armoireRoutes from './modules/armoires/armoiresRoutes.js'; // armoires
import cassierRoutes from './modules/cassiers/cassierRoutes.js'; // casiers
import dossierRoutes from './modules/dosiers/dosierRoute.js'; // dossiers
import fichierRoutes from './modules/fichiers/fichierRoutes.js'; // fichiers
import tagRoutes from './modules/tags/tagRoutes.js'; // tags
import auditRoutes from './modules/audit/auditRoutes.js'; // journal_activite
import encryptionRoutes from './modules/encryption/encryptionRoutes.js'; // encryption_keys
import backupRoutes from './modules/backup/backupRoutes.js'; // sauvegardes
import versionRoutes from './modules/versions/versionRoutes.js'; // versions
import restoreRoutes from './modules/restore/restoreRoutes.js'; // restaurations
import uploadRoutes from './modules/upload/uploadRoutes.js'; // upload
import ocrRoutes from './modules/ocr/ocrRoutes.js'; // ocr
import searchRoutes from './modules/search/searchRoute.js'; // routes de recherche
import favorisRoutes from './modules/favoris/favorisRoutes.js'; // favoris
import payments from './modules/payments/paymentsRoutes.js'; // payments et abonnements
import statsRoutes from './modules/stats/statsRoutes.js'; // statistiques
// app.use('/api/search', searchRoutes);

const app = express();

app.use(cors());

// Parsers JSON/urlencoded AVANT les routes qui attendent du JSON
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Arkiva Platform API' });
});

// Routes dans l'ordre des dépendances des tables
app.use('/api/auth', authRoutes);
app.use('/api/entreprise', entrepriseRoutes);
app.use('/api/armoire', armoireRoutes);
app.use('/api/casier', cassierRoutes);
app.use('/api/dosier', dossierRoutes);
app.use('/api/fichier', fichierRoutes);
app.use('/api/tag', tagRoutes);
app.use('/api/audit', auditRoutes);
app.use('/api/encryption', encryptionRoutes);
app.use('/api/sauvegardes', backupRoutes);
app.use('/api/versions', versionRoutes);
app.use('/api/restaurations', restoreRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/ocr', ocrRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/favoris', favorisRoutes);
app.use('/api/payments', payments);
app.use('/api/stats', statsRoutes);
// app.use('/api/search', searchRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Erreur détaillée:', err);
  res.status(500).json({ 
    error: 'Something went wrong!',
    details: err.message
  });
});

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`🚀 Server is running at: http://localhost:${PORT}`);
});

export default app; 
