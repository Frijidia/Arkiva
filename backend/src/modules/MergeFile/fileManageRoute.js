import express from 'express';

import {
   mergeSelectedPages,
   mergePdfs,
   getPdfPageCount

   
} from './fileManageControllers.js';

const router = express.Router();

// router.use(verifyToken);

router.post('/mergefile', mergePdfs);
router.post('/extracfile', mergeSelectedPages);
router.post('/getpagecount', getPdfPageCount);

export default router;
