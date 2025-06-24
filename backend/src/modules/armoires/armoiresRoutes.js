import express from 'express';
import {
   CreateArmoire,
   RenameArmoire,
   GetAllArmoires,
   DeleteArmoire
   
} from './armoireControllers.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';
import { checkSubscriptionStatus, checkArmoireAccess } from '../payments/subscriptionMiddleware.js';


const router = express.Router();

router.use(verifyToken);

// Routes qui nécessitent un abonnement actif
router.post('/', checkRole(['admin', 'contributeur']), checkSubscriptionStatus, CreateArmoire);
router.put('/:armoire_id', checkRole(['admin', 'contributeur']), checkArmoireAccess, RenameArmoire);
router.get('/:entreprise_id', checkRole(['admin', 'contributeur']), GetAllArmoires);
router.delete('/:armoire_id', checkRole(['admin', 'contributeur']), checkArmoireAccess, DeleteArmoire);


export default router;
