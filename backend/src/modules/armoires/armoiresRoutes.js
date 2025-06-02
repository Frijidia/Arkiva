import express from 'express';
import {
   CreateArmoire,
   RenameArmoire,
   GetAllArmoires,
   DeleteArmoire
   
} from './armoireControllers.js';

const router = express.Router();

router.post('/', CreateArmoire);
router.put('/:armoire_id', RenameArmoire);
router.get('/getarmoires', GetAllArmoires);
router.delete('/:armoire_id', DeleteArmoire);




export default router;
