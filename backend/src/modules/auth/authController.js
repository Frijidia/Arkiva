import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../config/database.js';
import crypto from 'crypto';
import nodemailer from 'nodemailer';


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
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.json({ token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Récupérer les utilisateurs avec le rôle "user"
export const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT user_id, email, username, role FROM users`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};

