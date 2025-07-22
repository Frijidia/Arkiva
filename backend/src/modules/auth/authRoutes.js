import express from 'express';
import {
    register,
    login,
    logout,
    getMe,
    getUsers,
    updateUserRole,
    enable2FA,
    verify2FA,
    updateUserInfo,
    deleteOwnAccount,
    deleteUserAccount,
    getUsersByEntreprise
  } from './authController.js';
import { verifyToken, checkRole, check2FA } from './authMiddleware.js';
  
const router = express.Router();

// Routes publiques
router.post('/register', register);
router.post('/login', login);

// Routes protégées
router.post('/logout', verifyToken, logout);
router.get('/me', verifyToken, getMe);
router.post('/2fa/enable', verifyToken, enable2FA);
router.post('/2fa/verify', verifyToken, verify2FA);
router.put('/me', verifyToken, updateUserInfo);
router.delete('/me', verifyToken, deleteOwnAccount);

// Routes admin
router.get('/users', verifyToken, checkRole(['admin']), getUsers);
router.get('/entreprise/:entrepriseId/users', verifyToken, checkRole(['admin']), getUsersByEntreprise);
router.put('/users/:id', verifyToken, checkRole(['admin']), updateUserRole);
router.delete('/users/:id', verifyToken, checkRole(['admin']), deleteUserAccount);

// Exportation du router avec ES Modules
export default router;
