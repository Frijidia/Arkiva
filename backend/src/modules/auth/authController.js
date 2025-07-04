import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../config/database.js';
import crypto from 'crypto';
import nodemailer from 'nodemailer';
//import './authModels.js';
import { enable2FA as enable2FAService, verify2FACode, send2FACode } from './twoFactorService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';

// Vérifier si c'est le premier utilisateur
const isFirstUser = async () => {
    const result = await pool.query('SELECT COUNT(*) FROM users');
    return parseInt(result.rows[0].count) === 0;
};

// Inscription
export const register = async (req, res) => {
    const { email, password, username } = req.body;

    try {
        // Vérifier si l'email existe déjà
        const existingUser = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );

        if (existingUser.rows.length > 0) {
            return res.status(400).json({ message: 'Cet email est déjà utilisé' });
        }

        // Hasher le mot de passe
        const hashedPassword = await bcrypt.hash(password, 10);

        // Définir le rôle comme admin
        const role = 'admin';

        // Créer l'utilisateur (insertion dans password)
        const result = await pool.query(
            `INSERT INTO users (email, password, username, role) 
             VALUES ($1, $2, $3, $4) 
             RETURNING user_id, email, username, role`,
            [email, hashedPassword, username, role]
        );

        // Générer le token
        const token = jwt.sign(
            { 
                userId: result.rows[0].user_id,
                email: result.rows[0].email,
                role: result.rows[0].role
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(201).json({
            message: 'Compte administrateur créé avec succès',
            user: {
                id: result.rows[0].user_id,
                email: result.rows[0].email,
                username: result.rows[0].username,
                role: result.rows[0].role
            },
            token
        });
    } catch (error) {
        console.error('Erreur lors de l\'inscription:', error);
        res.status(500).json({ message: 'Erreur lors de l\'inscription' });
    }
};


// Connexion
export const login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

        if (result.rows.length === 0) {
            return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
        }

        const user = result.rows[0];

        // Debug: Vérifier les valeurs
        console.log('🔍 Debug login:');
        console.log('  - password (from request):', typeof password, password ? '***' : 'null/undefined');
        console.log('  - user.password (from DB):', typeof user.password, user.password ? '***' : 'null/undefined');
        console.log('  - user object keys:', Object.keys(user));

        // Vérifier le mot de passe (utiliser password)
        if (!user.password) {
            console.error('❌ Mot de passe manquant en base de données pour l\'utilisateur:', user.email);
            return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
        }

        // Générer le token
        const token = jwt.sign(
            { userId: user.user_id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Logger la connexion avec un message humain
        const now = new Date();
        const message = `L'utilisateur ${user.username} (${user.email}) s'est connecté le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}.`;
        await logAction(
            user.user_id,
            ACTIONS.LOGIN,
            TARGET_TYPES.USER,
            user.user_id,
            { ip: req.ip, message }
        );

        res.json({ token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Déconnexion
export const logout = async (req, res) => {
    try {
        // Logger la déconnexion
        await logAction(
            req.user.user_id,
            ACTIONS.LOGOUT,
            TARGET_TYPES.USER,
            req.user.user_id,
            { ip: req.ip }
        );

        res.json({ message: 'Déconnexion réussie' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur lors de la déconnexion' });
    }
};


// Obtenir les informations de l'utilisateur connecté
export const getMe = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT 
                user_id,
                entreprise_id,
                email,
                username,
                role,
                two_factor_enabled,
                two_factor_secret,
                two_factor_method,
                two_factor_code,
                two_factor_code_expires,
                created_at
             FROM users 
             WHERE user_id = $1`,
            [req.user.user_id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        // On renomme user_id en id pour le frontend si besoin
        const user = result.rows[0];
        const userResponse = {
            id: user.user_id,
            email: user.email,
            username: user.username,
            role: user.role,
            entreprise_id: user.entreprise_id,
            two_factor_enabled: user.two_factor_enabled,
            two_factor_secret: user.two_factor_secret,
            two_factor_method: user.two_factor_method,
            two_factor_code: user.two_factor_code,
            two_factor_code_expires: user.two_factor_code_expires,
            created_at: user.created_at
        };

        res.json(userResponse);
    } catch (error) {
        console.error('Erreur dans getMe:', error);
        res.status(500).json({ message: 'Erreur du serveur', details: error.message });
    }
};


// Obtenir tous les utilisateurs (admin uniquement)
export const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT user_id, email, username, role, created_at FROM users'
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Modifier le rôle d'un utilisateur (admin uniquement)
export const updateUserRole = async (req, res) => {
    const { id } = req.params;
    const { role } = req.body;

    if (!['admin', 'contributeur', 'lecteur', 'user'].includes(role)) {
        return res.status(400).json({ message: 'Rôle invalide' });
    }

    try {
        const result = await pool.query(
            'UPDATE users SET role = $1 WHERE user_id = $2 RETURNING user_id, email, username, role',
            [role, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        // Logger le changement de rôle
        await logAction(
            req.user.user_id,
            ACTIONS.CHANGE_ROLE,
            TARGET_TYPES.USER,
            id,
            { new_role: role }
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Activer la 2FA
export const enable2FA = async (req, res) => {
    const { method } = req.body;
    const userId = req.user.user_id;

    if (!['email', 'otp'].includes(method)) {
        return res.status(400).json({ message: 'Méthode 2FA invalide' });
    }

    try {
        const result = await enable2FAService(userId, method);
        
        // Logger l'activation de la 2FA
        await logAction(
            userId,
            ACTIONS.ENABLE_2FA,
            TARGET_TYPES.USER,
            userId,
            { method }
        );

        res.json({ 
            message: '2FA activée avec succès', 
            method,
            note: method === 'email' ? 'Un code a été envoyé à votre adresse email' : 'Utilisez votre application OTP'
        });
    } catch (error) {
        console.error('Erreur lors de l\'activation de la 2FA:', error);
        res.status(500).json({ message: 'Erreur lors de l\'activation de la 2FA' });
    }
};

// Vérifier le code 2FA
export const verify2FA = async (req, res) => {
    const { code } = req.body;
    const userId = req.user.user_id;

    try {
        const result = await verify2FACode(userId, code);
        
        if (!result.valid) {
            return res.status(400).json({ message: result.message });
        }

        // Générer un nouveau token avec un flag 2FA vérifié
        const userResult = await pool.query(
            'SELECT user_id, email, role FROM users WHERE user_id = $1',
            [userId]
        );

        const user = userResult.rows[0];
        const token = jwt.sign(
            { 
                userId: user.user_id, 
                email: user.email,
                twoFactorVerified: true 
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.json({ 
            message: '2FA vérifiée avec succès',
            token
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur lors de la vérification du code 2FA' });
    }
};

// Mettre à jour les informations de l'utilisateur
export const updateUserInfo = async (req, res) => {
    const { username } = req.body;
    const userId = req.user.user_id;

    try {
        const result = await pool.query(
            'UPDATE users SET username = $1 WHERE user_id = $2 RETURNING user_id, email, username, role',
            [username, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        res.json({
            message: 'Informations mises à jour avec succès',
            user: result.rows[0]
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur lors de la mise à jour des informations' });
    }
};

// Supprimer son propre compte
export const deleteOwnAccount = async (req, res) => {
    const userId = req.user.user_id;

    try {
        // Vérifier si l'utilisateur existe
        const userCheck = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        // Supprimer l'utilisateur
        await pool.query('DELETE FROM users WHERE user_id = $1', [userId]);

        res.json({ message: 'Compte supprimé avec succès' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur lors de la suppression du compte' });
    }
};

// Supprimer un compte utilisateur (admin uniquement)
export const deleteUserAccount = async (req, res) => {
    const { id } = req.params;

    try {
        // Vérifier si l'utilisateur existe
        const userCheck = await pool.query('SELECT * FROM users WHERE user_id = $1', [id]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        // Empêcher la suppression d'un compte admin par un autre admin
        if (userCheck.rows[0].role === 'admin') {
            return res.status(403).json({ message: 'Impossible de supprimer un compte administrateur' });
        }

        // Supprimer l'utilisateur
        await pool.query('DELETE FROM users WHERE user_id = $1', [id]);

        res.json({ message: 'Compte utilisateur supprimé avec succès' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur lors de la suppression du compte utilisateur' });
    }
};

// Obtenir les utilisateurs par entreprise
export const getUsersByEntreprise = async (req, res) => {
    try {
        const { entrepriseId } = req.params;

        const result = await pool.query(
            `SELECT 
                user_id,
                email,
                username,
                role,
                created_at,
                two_factor_enabled
             FROM users 
             WHERE entreprise_id = $1
             ORDER BY created_at DESC`,
            [entrepriseId]
        );

        res.json({
            message: 'Liste des utilisateurs récupérée avec succès',
            users: result.rows
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des utilisateurs:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la récupération des utilisateurs',
            details: error.message 
        });
    }
};

