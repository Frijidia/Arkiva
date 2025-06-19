import express from 'express';

import {
    getFilesByTag,
    searchFichiersByOcrContent,
   getFichiersByDate,
   searchFichiersByFlexibleLocation

} from './searchControllers.js';

const router = express.Router();

router.get('/:tag_id/tag', getFilesByTag);
router.get('/:searchTerm/ocr', searchFichiersByOcrContent);
router.get('/seachbydate', getFichiersByDate);
router.get('/seachbyname', searchFichiersByFlexibleLocation);



export default router;
