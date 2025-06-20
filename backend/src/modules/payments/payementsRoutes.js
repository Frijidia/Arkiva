import express from 'express';
import { verifyToken } from '../auth/authMiddleware';
import {
    chooseSubscription,
    paySubscription,
    getSubscription,
    getinvoice
} from './paymentsController.js';

const router = express.Router();
// Route pour choisir un abonnement
router.post('/chooseSubscription', verifyToken, chooseSubscription);
// Route pour payer l'abonnement
router.post('/subscribe', verifyToken, paySubscription);
// Route pour récupérer les informations sur l'abonnement actif ou la liste des offres
router.get('/getsubscribtion', verifyToken, getSubcription);
// Route pour récupérer les factures de l'utilisateur
router.get('/invoice', verifyToken, getinvoice);


export default router; 