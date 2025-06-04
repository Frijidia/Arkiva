import express from 'express';
import {
   CreateCasier,
   RenameCasier,
   DeleteCasier,
   GetAllCasiers,
   GetCasiersByArmoire
   
} from './cassierContollers.js';

const router = express.Router();

router.post('/', CreateCasier);
router.put('/:cassier_id', RenameCasier);
router.get('/getcasiers', GetAllCasiers);
router.delete('/:cassier_id', DeleteCasier);
router.get('/:armoire_id', GetCasiersByArmoire);



export default router;
