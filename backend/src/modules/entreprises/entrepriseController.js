import pool from '../../config/database.js';
import bcrypt from 'bcrypt';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';
//import "./entrepriseModels.js";

// Créer une nouvelle entreprise
export const create = async (req, res) => {
    const { nom, email, telephone, adresse, logo_url, plan_abonnement, armoire_limit } = req.body;
    const adminId = req.user.user_id;
    
    try {
        // Commencer une transaction
        await pool.query('BEGIN');

        // Créer l'ent  reprise
        const entrepriseResult = await pool.query(
            `INSERT INTO entreprises 
             (nom, email, telephone, adresse, logo_url, plan_abonnement, armoire_limit) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) 
             RETURNING *`,
            [nom, email, telephone, adresse, logo_url, plan_abonnement, armoire_limit || 2]
        );

        const entreprise = entrepriseResult.rows[0];

        // Mettre à jour l'entreprise_id de l'admin
        await pool.query(
            'UPDATE users SET entreprise_id = $1 WHERE user_id = $2',
            [entreprise.entreprise_id, adminId]
        );

        // Logger l'action
        await logAction(
            adminId,
            ACTIONS.CREATE,
            TARGET_TYPES.ENTREPRISE,
            entreprise.entreprise_id,
            { nom, email, armoire_limit: entreprise.armoire_limit }
        );

        // Valider la transaction
        await pool.query('COMMIT');
        
        // Récupérer l'utilisateur mis à jour
        const userMaj = await pool.query(
            'SELECT user_id, email, username, role, entreprise_id FROM users WHERE user_id = $1',
            [adminId]
        );

        // Envoyer l'entreprise ET l'utilisateur mis à jour dans la réponse
        res.status(201).json({
            message: 'Entreprise créée avec succès',
            entreprise,
            user: userMaj.rows[0]
        });
    } catch (error) {
        // Annuler la transaction en cas d'erreur
        await pool.query('ROLLBACK');
        console.error('Erreur lors de la création de l\'entreprise:', error);
        if (error.code === '23505') {
            res.status(400).json({ message: 'Une entreprise avec cet email existe déjà' });
        } else {
            res.status(500).json({ message: 'Erreur lors de la création de l\'entreprise' });
        }
    }
};

// Obtenir une entreprise par son ID
export const getById = async (req, res) => {
    try {
        // Vérifier si l'utilisateur est admin de cette entreprise
        const userCheck = await pool.query(
            'SELECT * FROM users WHERE user_id = $1 AND role = $2 AND entreprise_id = $3',
            [req.user.user_id, 'admin', req.params.id]
        );

        if (!userCheck.rows[0]) {
            return res.status(403).json({ 
                message: 'Vous n\'avez pas les droits pour voir les informations de cette entreprise' 
            });
        }

        const result = await pool.query(
            'SELECT * FROM entreprises WHERE entreprise_id = $1',
            [req.params.id]
        );
        
        if (!result.rows[0]) {
            return res.status(404).json({ message: 'Entreprise non trouvée' });
        }
        
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'entreprise:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération de l\'entreprise' });
    }
};

// Mettre à jour une entreprise
export const update = async (req, res) => {
    const { nom, email, telephone, adresse, logo_url, plan_abonnement, is_active } = req.body;
    
    try {
        const result = await pool.query(
            `UPDATE entreprises 
             SET nom = COALESCE($1, nom),
                 email = COALESCE($2, email),
                 telephone = COALESCE($3, telephone),
                 adresse = COALESCE($4, adresse),
                 logo_url = COALESCE($5, logo_url),
                 plan_abonnement = COALESCE($6, plan_abonnement),
                 is_active = COALESCE($7, is_active)
             WHERE entreprise_id = $8 
             RETURNING *`,
            [nom, email, telephone, adresse, logo_url, plan_abonnement, is_active, req.params.id]
        );
        
        if (!result.rows[0]) {
            return res.status(404).json({ message: 'Entreprise non trouvée' });
        }
        
        res.json({
            message: 'Entreprise mise à jour avec succès',
            entreprise: result.rows[0]
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de l\'entreprise:', error);
        if (error.code === '23505') {
            res.status(400).json({ message: 'Une entreprise avec cet email existe déjà' });
        } else {
            res.status(500).json({ message: 'Erreur lors de la mise à jour de l\'entreprise' });
        }
    }
};

// Supprimer une entreprise
export const remove = async (req, res) => {
    try {
        const result = await pool.query(
            'DELETE FROM entreprises WHERE entreprise_id = $1 RETURNING *',
            [req.params.id]
        );
        
        if (!result.rows[0]) {
            return res.status(404).json({ message: 'Entreprise non trouvée' });
        }
        
        res.json({ message: 'Entreprise supprimée avec succès' });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'entreprise:', error);
        res.status(500).json({ message: 'Erreur lors de la suppression de l\'entreprise' });
    }
};

// Lister toutes les entreprises
export const list = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM entreprises ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des entreprises:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des entreprises' });
    }
};

// Ajouter un utilisateur à l'entreprise
export const addUser = async (req, res) => {
    const { email, password, username, role } = req.body;
    const entrepriseId = req.params.id;

    try {
        // Vérifier si l'utilisateur qui fait la requête est admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({ 
                message: 'Seuls les administrateurs peuvent ajouter des utilisateurs' 
            });
        }

        // Vérifier si l'admin appartient à cette entreprise
        if (req.user.entreprise_id !== parseInt(entrepriseId)) {
            return res.status(403).json({ 
                message: 'Vous n\'avez pas les droits pour ajouter des utilisateurs à cette entreprise' 
            });
        }

        // Vérifier si l'email existe déjà dans cette entreprise
        const existingUser = await pool.query(
            'SELECT * FROM users WHERE email = $1 AND entreprise_id = $2',
            [email, entrepriseId]
        );

        if (existingUser.rows.length > 0) {
            return res.status(400).json({ 
                message: 'Un utilisateur avec cet email existe déjà dans cette entreprise' 
            });
        }

        // Hasher le mot de passe
        const hashedPassword = await bcrypt.hash(password, 10);

        // Créer l'utilisateur
        const result = await pool.query(
            `INSERT INTO users 
             (email, password, username, role, entreprise_id) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING user_id, email, username, role`,
            [email, hashedPassword, username, role, entrepriseId]
        );

        // Logger l'action
        await logAction(
            req.user.user_id,
            ACTIONS.ADD_USER,
            TARGET_TYPES.ENTREPRISE,
            entrepriseId,
            { email, username, role }
        );

        res.status(201).json({
            message: 'Utilisateur ajouté avec succès',
            user: {
                id: result.rows[0].user_id,
                email: result.rows[0].email,
                username: result.rows[0].username,
                role: result.rows[0].role
            }
        });
    } catch (error) {
        console.error('Erreur lors de l\'ajout de l\'utilisateur:', error);
        res.status(500).json({ message: 'Erreur lors de l\'ajout de l\'utilisateur' });
    }
}; 