import express from 'express';

import {
   mergeSelectedPages,
   mergePdfs

   
} from './fileManageControllers.js';

const router = express.Router();

// router.use(verifyToken);

router.post('/mergefile', mergePdfs);
router.post('/extracfile', mergeSelectedPages);




export default router;
