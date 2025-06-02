import express from 'express';

import {
    getFichiersByDossierId,
    renameFichier,
    deleteFichier,
    getSignedUrlForFile

   
} from './fichierControllers.js';

const router = express.Router();

router.put('/:dossier_id', renameFichier);
router.delete('/:dossier_id', deleteFichier);
router.get('/:fichier_id', getSignedUrlForFile);



export default router;
