import express from 'express';
import { verifyToken, checkRole} from '../auth/authMiddleware.js';
import {
    chooseSubscription,
    processPayment,
    getSubscriptions,
    getSubscriptionHistory,
    getCurrentSubscription,
    feexPayWebhook
} from './paymentsController.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Route pour servir le frontend de test (pas besoin d'authentification)
router.get('/test', (req, res) => {
    res.sendFile(path.join(__dirname, 'payment-test-frontend.html'));
});

// Webhook FeexPay (pas besoin d'authentification) - doit être avant le middleware d'auth
router.post('/webhook', feexPayWebhook);

// Routes protégées par authentification
router.use(verifyToken);

// Route pour récupérer les abonnements disponibles
router.get('/subscriptions', getSubscriptions);

// Route pour vérifier le statut de l'abonnement actuel
router.get('/current-subscription', getCurrentSubscription);

// Route pour récupérer l'historique des abonnements
router.get('/history', getSubscriptionHistory);

// Route pour choisir un abonnement (calcul du coût)
router.post('/choose-subscription', chooseSubscription);

// Route pour effectuer le paiement
router.post('/process-payment', processPayment);

export default router; 