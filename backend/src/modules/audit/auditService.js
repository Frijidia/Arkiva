import pool from '../../config/database.js';

// Types d'actions possibles
export const ACTIONS = {
    CREATE: 'create',
    UPDATE: 'update',
    DELETE: 'delete',
    RESTORE: 'restore',
    LOGIN: 'login',
    LOGOUT: 'logout',
    ENABLE_2FA: 'enable_2fa',
    DISABLE_2FA: 'disable_2fa',
    ADD_USER: 'add_user',
    REMOVE_USER: 'remove_user',
    CHANGE_ROLE: 'change_role'
};

// Types de cibles possibles
export const TARGET_TYPES = {
    USER: 'user',
    FILE: 'file',
    FOLDER: 'folder',
    CABINET: 'cabinet',
    ENTERPRISE: 'enterprise'
};

// Enregistrer une action dans le journal
export const logAction = async (userId, action, targetType, targetId, details = {}) => {
    try {
        const result = await pool.query(
            `INSERT INTO journal_activite 
             (user_id, action, type_cible, id_cible, details) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING *`,
            [userId, action, targetType, targetId, details]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de l\'enregistrement du log:', error);
        throw error;
    }
};

// Obtenir les logs d'un utilisateur
export const getUserLogs = async (userId, limit = 50, offset = 0) => {
    try {
        const result = await pool.query(
            `SELECT * FROM journal_activite 
             WHERE user_id = $1 
             ORDER BY created_at DESC 
             LIMIT $2 OFFSET $3`,
            [userId, limit, offset]
        );
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        throw error;
    }
};

// Obtenir les logs d'une cible spécifique
export const getTargetLogs = async (targetType, targetId, limit = 50, offset = 0) => {
    try {
        const result = await pool.query(
            `SELECT ja.*, u.email as user_email, u.username 
             FROM journal_activite ja
             JOIN users u ON ja.user_id = u.user_id
             WHERE type_cible = $1 AND id_cible = $2 
             ORDER BY created_at DESC 
             LIMIT $3 OFFSET $4`,
            [targetType, targetId, limit, offset]
        );
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        throw error;
    }
};

// Obtenir les logs d'une entreprise
export const getEnterpriseLogs = async (entrepriseId, limit = 50, offset = 0) => {
    try {
        const result = await pool.query(
            `SELECT ja.*, u.email as user_email, u.username 
             FROM journal_activite ja
             JOIN users u ON ja.user_id = u.user_id
             WHERE u.entreprise_id = $1 
             ORDER BY created_at DESC 
             LIMIT $2 OFFSET $3`,
            [entrepriseId, limit, offset]
        );
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        throw error;
    }
}; 