import express from 'express';
// import multer from 'multer';
import { uploadFiles } from './uploadControllers.js';
import { upload } from './uploadControllers.js';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import { checkSubscriptionStatus } from '../payments/subscriptionMiddleware.js';

const router = express.Router();
// const upload = multer({ storage: multer.memoryStorage() }); // mémoire temporaire

// Appliquer l'authentification et la vérification d'abonnement
router.post('/', verifyToken, checkRole(['admin', 'contributeur']), checkSubscriptionStatus, upload.array('files', 10), uploadFiles);

export default router;

