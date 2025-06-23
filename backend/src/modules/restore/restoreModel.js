import pool from '../../config/database.js';
import { v4 as uuidv4 } from 'uuid';

// Créer une nouvelle restauration
const createRestore = async (restoreData) => {
    const { backup_id, type, cible_id, entreprise_id, declenche_par_id } = restoreData;
    const id = uuidv4();
    
    const query = `
        INSERT INTO restores (
            id, backup_id, type, cible_id, entreprise_id, 
            declenche_par_id, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
        RETURNING *
    `;
    
    const values = [id, backup_id, type, cible_id, entreprise_id, declenche_par_id];
    const result = await pool.query(query, values);
    return result.rows[0];
};

// Obtenir toutes les restaurations
const getAllRestores = async () => {
    const query = 'SELECT * FROM restores ORDER BY created_at DESC';
    const result = await pool.query(query);
    return result.rows;
};

// Obtenir une restauration par ID
const getRestoreById = async (id) => {
    const query = 'SELECT * FROM restores WHERE id = $1';
    const result = await pool.query(query, [id]);
    return result.rows[0];
};

// Obtenir les restaurations par entreprise
const getRestoresByEntreprise = async (entrepriseId) => {
    const query = 'SELECT * FROM restores WHERE entreprise_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [entrepriseId]);
    return result.rows;
};

// Obtenir les restaurations par type
const getRestoresByType = async (type) => {
    const query = 'SELECT * FROM restores WHERE type = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [type]);
    return result.rows;
};

// Supprimer une restauration
const deleteRestore = async (id) => {
    const query = 'DELETE FROM restores WHERE id = $1 RETURNING *';
    const result = await pool.query(query, [id]);
    return result.rows[0];
};

export default {
    createRestore,
    getAllRestores,
    getRestoreById,
    getRestoresByEntreprise,
    getRestoresByType,
    deleteRestore
}; 