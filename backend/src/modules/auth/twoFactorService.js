import nodemailer from 'nodemailer';
import crypto from 'crypto';
import pool from '../../config/database.js';

// Configuration du transporteur email
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
    }
});

// Générer un code 2FA
const generate2FACode = () => {
    return crypto.randomInt(100000, 999999).toString();
};

// Envoyer le code par email
export const send2FACode = async (email, code) => {
    const mailOptions = {
        from: process.env.SMTP_FROM,
        to: email,
        subject: 'Code de vérification 2FA',
        html: `
            <h1>Votre code de vérification</h1>
            <p>Votre code de vérification est : <strong>${code}</strong></p>
            <p>Ce code est valable pendant 5 minutes.</p>
        `
    };

    try {
        await transporter.sendMail(mailOptions);
        return true;
    } catch (error) {
        console.error('Erreur lors de l\'envoi du code 2FA:', error);
        return false;
    }
};

// Activer la 2FA
export const enable2FA = async (userId, method) => {
    const code = generate2FACode();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    try {
        // Récupérer l'email de l'utilisateur
        const userResult = await pool.query(
            'SELECT email FROM users WHERE user_id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            throw new Error('Utilisateur non trouvé');
        }

        const userEmail = userResult.rows[0].email;

        // Si la méthode est email, envoyer le code
        if (method === 'email') {
            const sent = await send2FACode(userEmail, code);
            if (!sent) {
                // Si l'envoi échoue, on stocke juste le code sans activer la 2FA
                await pool.query(
                    `UPDATE users 
                     SET two_factor_code = $1,
                         two_factor_code_expires = $2,
                         two_factor_method = $3
                     WHERE user_id = $4`,
                    [code, expiresAt, method, userId]
                );
                throw new Error('Erreur lors de l\'envoi du code');
            }
        }

        // Si on arrive ici, c'est que l'envoi a réussi ou que la méthode n'est pas email
        // On peut donc activer la 2FA
        await pool.query(
            `UPDATE users 
             SET two_factor_enabled = true, 
                 two_factor_secret = $1, 
                 two_factor_method = $2,
                 two_factor_code = $3,
                 two_factor_code_expires = $4
             WHERE user_id = $5`,
            [crypto.randomBytes(20).toString('hex'), method, code, expiresAt, userId]
        );

        return { success: true, method };
    } catch (error) {
        console.error('Erreur lors de l\'activation de la 2FA:', error);
        throw error;
    }
};

// Vérifier le code 2FA
export const verify2FACode = async (userId, code) => {
    try {
        const result = await pool.query(
            `SELECT two_factor_code, two_factor_code_expires 
             FROM users 
             WHERE user_id = $1 AND two_factor_enabled = true`,
            [userId]
        );

        if (result.rows.length === 0) {
            return { valid: false, message: '2FA non activée' };
        }

        const { two_factor_code, two_factor_code_expires } = result.rows[0];

        // Vérifier si le code a expiré
        if (new Date() > new Date(two_factor_code_expires)) {
            return { valid: false, message: 'Code expiré' };
        }

        // Vérifier si le code correspond
        if (code !== two_factor_code) {
            return { valid: false, message: 'Code invalide' };
        }

        // Code valide, on peut le supprimer
        await pool.query(
            `UPDATE users 
             SET two_factor_code = NULL, 
                 two_factor_code_expires = NULL 
             WHERE user_id = $1`,
            [userId]
        );

        return { valid: true };
    } catch (error) {
        console.error('Erreur lors de la vérification du code 2FA:', error);
        throw error;
    }
}; 