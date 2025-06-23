import express from 'express';
import { verifyToken, checkRole} from '../auth/authMiddleware.js';
import {
    chooseSubscription,
    // paySubscription,
    getSubscriptions,
    // getinvoice
} from './paymentsController.js';

const router = express.Router();

router.use(verifyToken);
router.use(checkRole(['admin']));

// Route pour choisir un abonnement
router.post('/chooseSubscription', chooseSubscription);

// Route pour payer l'abonnement
// router.post('/subscribe', verifyToken, paySubscription);

// Route pour récupérer les informations sur l'abonnement actif ou la liste des offres
router.get('/getsubscribtion', verifyToken, getSubscriptions);

// // Route pour récupérer les factures de l'utilisateur
// router.get('/invoice', verifyToken, getinvoice);


export default router; 