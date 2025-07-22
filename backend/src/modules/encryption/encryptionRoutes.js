import express from 'express';
import EncryptionController from './encryptionController.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';

const router = express.Router();

// Route pour générer une clé de chiffrement pour une entreprise
router.post(
    '/generate-key/:entrepriseId',
    verifyToken, checkRole(['admin']), 
    EncryptionController.generateKey
);

// Route pour chiffrer un fichier
router.post(
    '/encrypt/:entrepriseId', 
    verifyToken, 
    EncryptionController.uploadMiddleware(),
    EncryptionController.encryptFile
);

// Route pour déchiffrer un fichier
router.post(
    '/decrypt/:entrepriseId',
    verifyToken,
    EncryptionController.uploadMiddleware(),
    EncryptionController.decryptFile
);

export default router; 