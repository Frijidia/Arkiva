import express from 'express';

import {
    deleteTag,
    createTag,
    renameTag,
    getAllTags,
    addTagToFile,
    removeTagFromFile,
    getFilesByTag

   
} from './tagControllers.js';

const router = express.Router();

router.post('/', createTag);
router.put('/:tag_id', renameTag);
router.delete('/deletetag/:tag_id', deleteTag);
router.get('/', getAllTags);
router.get('/:tag_id', getFilesByTag);

router.delete('/removeTagFromFile', removeTagFromFile);
router.post('/addTagToFile', addTagToFile);





export default router;
