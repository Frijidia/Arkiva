import express from 'express';

import {
    CreateDossier,
    GetDossiersByCasier,
    DeleteDossier,
    RenameDossier,
    deplacerDossier

   
} from './dosierControllers.js';

const router = express.Router();

router.post('/', CreateDossier);
router.put('/:dossier_id', RenameDossier);
// router.get('/getcasiers', GetAllCasiers);
router.delete('/:dossier_id', DeleteDossier);
router.get('/:casier_id', GetDossiersByCasier);
router.put('/:id/deplacer', deplacerDossier);



export default router;
