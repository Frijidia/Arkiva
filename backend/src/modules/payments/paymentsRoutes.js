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

const router = express.Router();

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

// Webhook FeexPay (pas besoin d'authentification)
router.post('/webhook', feexPayWebhook);

export default router; 