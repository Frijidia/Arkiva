import express from 'express';
import {
    getStats,
    getAdmins,
    getContributeurs,
    getLecteurs,
    getStatsArmoires,
    getActivite,
    getStatsTypesFichiers,
    getCroissance,
    getStatsGlobales,
    getTableauBord,
    getLogs,
    getLogsStatsController,
    getLogsParUtilisateurController,
    getLogsParActionController,
    getLogsParCibleController,
    getTableauBordComplet
} from './statsController.js';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';

const router = express.Router();

// Routes pour les statistiques d'une entreprise spécifique
// Toutes ces routes nécessitent d'être connecté et d'avoir les rôles appropriés

// Statistiques générales d'une entreprise
router.get('/entreprise/:id', verifyToken, checkRole(['admin', 'contributeur']), getStats);

// Liste des utilisateurs par rôle
router.get('/entreprise/:id/admins', verifyToken, checkRole(['admin', 'contributeur']), getAdmins);
router.get('/entreprise/:id/contributeurs', verifyToken, checkRole(['admin', 'contributeur']), getContributeurs);
router.get('/entreprise/:id/lecteurs', verifyToken, checkRole(['admin', 'contributeur']), getLecteurs);

// Statistiques détaillées des armoires
router.get('/entreprise/:id/armoires', verifyToken, checkRole(['admin', 'contributeur']), getStatsArmoires);

// Activité récente
router.get('/entreprise/:id/activite', verifyToken, checkRole(['admin', 'contributeur']), getActivite);

// Statistiques par type de fichier
router.get('/entreprise/:id/types-fichiers', verifyToken, checkRole(['admin', 'contributeur']), getStatsTypesFichiers);

// Statistiques de croissance mensuelle
router.get('/entreprise/:id/croissance', verifyToken, checkRole(['admin', 'contributeur']), getCroissance);

// Tableau de bord complet (toutes les statistiques en une seule requête)
router.get('/entreprise/:id/tableau-bord', verifyToken, checkRole(['admin', 'contributeur']), getTableauBord);

// Routes pour les logs d'activité
router.get('/entreprise/:id/logs', verifyToken, checkRole(['admin', 'contributeur']), getLogs);
router.get('/entreprise/:id/logs/stats', verifyToken, checkRole(['admin', 'contributeur']), getLogsStatsController);
router.get('/entreprise/:id/logs/utilisateurs', verifyToken, checkRole(['admin', 'contributeur']), getLogsParUtilisateurController);
router.get('/entreprise/:id/logs/actions', verifyToken, checkRole(['admin', 'contributeur']), getLogsParActionController);
router.get('/entreprise/:id/logs/cibles', verifyToken, checkRole(['admin', 'contributeur']), getLogsParCibleController);

// Tableau de bord complet avec logs
router.get('/entreprise/:id/tableau-bord-complet', verifyToken, checkRole(['admin', 'contributeur']), getTableauBordComplet);

// Statistiques globales (admin seulement)
router.get('/globales', verifyToken, checkRole(['admin']), getStatsGlobales);

export default router; 