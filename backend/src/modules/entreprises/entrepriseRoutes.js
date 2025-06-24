import express from 'express';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import {
    create,
    getById,
    update,
    remove,
    list,
    addUser
} from './entrepriseController.js';

const router = express.Router();

// Routes protégées par authentification
router.use(verifyToken);

// Routes accessibles uniquement aux administrateurs
router.post('/', checkRole(['admin']), create);
router.put('/:id', checkRole(['admin']), update);
router.delete('/:id', checkRole(['admin']), remove);
router.post('/:id/users', checkRole(['admin']), addUser);

// Routes accessibles aux administrateurs et contributeurs
router.get('/', checkRole(['admin', 'contributeur']), list);
router.get('/:id', checkRole(['admin', 'contributeur']), getById);

export default router; 