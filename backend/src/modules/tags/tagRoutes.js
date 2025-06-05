import express from 'express';

import {
    deleteTag,
    createTag,
    renameTag,
    getAllTags,
    addTagToFile,
    removeTagFromFile,
    getFilesByTag,
    getTagSuggestions

   
} from './tagControllers.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';

const router = express.Router();

router.use(verifyToken);

router.post('/', checkRole(['admin', 'contributeur']), createTag);
router.put('/:tag_id', checkRole(['admin', 'contributeur']), renameTag);
router.delete('/deletetag/:tag_id', checkRole(['admin', 'contributeur']), deleteTag);
router.get('/', checkRole(['admin', 'contributeur']), getAllTags);
router.get('/:tag_id', checkRole(['admin', 'contributeur']), getFilesByTag);
router.get('/tagsuggestions', checkRole(['admin', 'contributeur']), getTagSuggestions);
router.delete('/removeTagFromFile', checkRole(['admin', 'contributeur']), removeTagFromFile);
router.post('/addTagToFile', checkRole(['admin', 'contributeur']), addTagToFile);





export default router;
