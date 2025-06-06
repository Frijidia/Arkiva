import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Configuration de dotenv
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '.env') });



// Import des routes
import authRoutes from './modules/auth/authRoutes.js'; // Routes d'authentification
import armoireRoutes from './modules/armoires/armoiresRoutes.js';
import cassierRoutes from './modules/cassiers/cassierRoutes.js';
import dossierRoutes from './modules/dosiers/dosierRoute.js';
import fichierRoutes from './modules/fichiers/fichierRoutes.js';
import uploadRoutes from './modules/upload/uploadRoutes.js';
import tagRoutes from './modules/tags/tagRoutes.js'

const app = express();

app.use(cors());

// Parsers JSON/urlencoded AVANT les routes qui attendent du JSON
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Arkiva Platform API' });
});



// Routes qui attendent du JSON
app.use('/api/auth', authRoutes);
app.use('/api/armoire', armoireRoutes);
app.use('/api/casier', cassierRoutes);
app.use('/api/dosier', dossierRoutes);
app.use('/api/fichier', fichierRoutes);
app.use('/api/upload', uploadRoutes)
app.use('/api/tag', tagRoutes)



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
