import jwt from 'jsonwebtoken';
import pool from '../../config/database.js';

// Middleware pour vérifier le token JWT
export const verifyToken = async (req, res, next) => {
    let token = req.headers.authorization?.split(' ')[1];
    // Ajout : accepte aussi le token dans la query string
    if (!token && req.query.token) {
        token = req.query.token;
    }

    if (!token) {
        return res.status(401).json({ message: 'Token manquant' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [decoded.userId]);
        
        if (result.rows.length === 0) {
            return res.status(401).json({ message: 'Utilisateur non trouvé' });
        }

        req.user = result.rows[0];
        next();
    } catch (error) {
        return res.status(401).json({ message: 'Token invalide' });
    }
};

// Middleware pour vérifier les rôles
export const checkRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ message: 'Non authentifié' });
        }

        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ message: 'Accès non autorisé' });
        }

        next();
    };
};

// Middleware pour vérifier la 2FA si activée
export const check2FA = async (req, res, next) => {
    if (!req.user.two_factor_enabled) {
        return next();
    }

    const twoFactorToken = req.headers['x-2fa-token'];
    if (!twoFactorToken) {
        return res.status(401).json({ message: 'Token 2FA requis' });
    }

    // Ici, vous pouvez ajouter la logique de vérification du token 2FA
    // Pour l'instant, on passe simplement
    next();
}; 