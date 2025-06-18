import express from 'express';

import {
   getFavoris,
   addFavori,
   removeFavori

   
} from './favorisControllers.js';

const router = express.Router();

router.post('/', addFavori);
router.delete('/:user_id/:fichier_id', removeFavori);
router.get('/:user_id', getFavoris);



export default router;
