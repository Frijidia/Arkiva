import express from 'express';
import {
   CreateCasier,
   RenameCasier,
   DeleteCasier,
   GetAllCasiers,
   GetCasiersByArmoire,
   deplacerCasier
   
} from './cassierContollers.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';

const router = express.Router();

router.use(verifyToken);

router.post('/', checkRole(['admin', 'contributeur']), CreateCasier);
router.put('/:cassier_id', checkRole(['admin', 'contributeur']), RenameCasier);
router.get('/getcasiers', checkRole(['admin', 'contributeur']), GetAllCasiers);
router.delete('/:cassier_id', checkRole(['admin', 'contributeur']), DeleteCasier);
router.get('/:armoire_id', checkRole(['admin', 'contributeur']), GetCasiersByArmoire);
router.put('/:id/deplacer', deplacerCasier);



export default router;
