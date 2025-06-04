import express from 'express';

import {
    getFichiersByDossierId,
    renameFichier,
    deleteFichier,
    displayFichier,
    telechargerFichier,
    getFichierById

   
} from './fichierControllers.js';

const router = express.Router();

router.put('/:dossier_id', renameFichier);
router.delete('/:dossier_id', deleteFichier);
router.get('/:fichier_id', displayFichier);
router.get('/getfile/:dossier_id',  getFichiersByDossierId);
router.get('/telecharger/:fichier_id', telechargerFichier);
router.get('/getinfofile/:fichier_id', getFichierById);




export default router;
