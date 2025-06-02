import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../config/database.js';
import crypto from 'crypto';
import nodemailer from 'nodemailer';
import { enable2FA as enable2FAService, verify2FACode } from './twoFactorService.js';


// Inscription
export const register = async (req, res) => {
    const { email, password, username } = req.body;
    let { role } = req.body;

    if (!role) {
        role = 'user';
    }
    try {
        const hash = await bcrypt.hash(password, 10); 

        const result = await pool.query(
            `INSERT INTO users (email, password, username, role) 
             VALUES ($1, $2, $3, $4) 
             RETURNING user_id, email, username, role`,
            [email, hash, username, role]
        );

        const user = result.rows[0];

        const token = jwt.sign(
            { userId: user.user_id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.status(201).json({ token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
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

        // Vérifier le mot de passe
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

        res.json({ token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Déconnexion
export const logout = async (req, res) => {
    try {
        // On peut ajouter le token à une liste noire si nécessaire
        // Pour l'instant, on renvoie juste un succès
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
            'SELECT user_id, email, username, role, two_factor_enabled FROM users WHERE user_id = $1',
            [req.user.user_id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
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
        res.json({ 
            message: '2FA activée avec succès', 
            method,
            note: method === 'email' ? 'Un code a été envoyé à votre adresse email' : 'Utilisez votre application OTP'
        });
    } catch (error) {
        console.error(error);
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

