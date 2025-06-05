import express from 'express';
import {
   CreateArmoire,
   RenameArmoire,
   GetAllArmoires,
   DeleteArmoire
   
} from './armoireControllers.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';


const router = express.Router();

router.use(verifyToken);

router.post('/', checkRole(['admin', 'contributeur']), CreateArmoire);
router.put('/:armoire_id', checkRole(['admin', 'contributeur']), RenameArmoire);
router.get('/:entreprise_id', checkRole(['admin', 'contributeur']), GetAllArmoires);
router.delete('/:armoire_id', checkRole(['admin', 'contributeur']), DeleteArmoire);


export default router;
