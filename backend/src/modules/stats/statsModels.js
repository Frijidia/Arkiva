import pool from '../../config/database.js';
import { getEntrepriseLogs } from '../audit/auditService.js';

// Obtenir les statistiques générales d'une entreprise
export const getEntrepriseStats = async (entrepriseId) => {
    try {
        const result = await pool.query(
            `SELECT 
                -- Nombre total d'utilisateurs
                (SELECT COUNT(*) FROM users WHERE entreprise_id = $1) as nombre_utilisateurs,
                
                -- Nombre d'utilisateurs par rôle
                (SELECT COUNT(*) FROM users WHERE entreprise_id = $1 AND role = 'admin') as nombre_admins,
                (SELECT COUNT(*) FROM users WHERE entreprise_id = $1 AND role = 'contributeur') as nombre_contributeurs,
                (SELECT COUNT(*) FROM users WHERE entreprise_id = $1 AND role = 'lecteur') as nombre_lecteurs,
                
                -- Nombre d'armoires
                (SELECT COUNT(*) FROM armoires WHERE entreprise_id = $1) as nombre_armoires,
                
                -- Nombre de casiers
                (SELECT COUNT(*) FROM casiers WHERE armoire_id IN (
                    SELECT armoire_id FROM armoires WHERE entreprise_id = $1
                )) as nombre_casiers,
                
                -- Nombre de dossiers
                (SELECT COUNT(*) FROM dossiers WHERE cassier_id IN (
                    SELECT cassier_id FROM casiers WHERE armoire_id IN (
                        SELECT armoire_id FROM armoires WHERE entreprise_id = $1
                    )
                )) as nombre_dossiers,
                
                -- Nombre de fichiers
                (SELECT COUNT(*) FROM fichiers WHERE dossier_id IN (
                    SELECT dossier_id FROM dossiers WHERE cassier_id IN (
                        SELECT cassier_id FROM casiers WHERE armoire_id IN (
                            SELECT armoire_id FROM armoires WHERE entreprise_id = $1
                        )
                    )
                )) as nombre_fichiers,
                
                -- Taille totale des fichiers (en octets)
                (SELECT COALESCE(SUM(taille), 0) FROM fichiers WHERE dossier_id IN (
                    SELECT dossier_id FROM dossiers WHERE cassier_id IN (
                        SELECT cassier_id FROM casiers WHERE armoire_id IN (
                            SELECT armoire_id FROM armoires WHERE entreprise_id = $1
                        )
                    )
                )) as taille_totale_fichiers
            `,
            [entrepriseId]
        );
        
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques de l\'entreprise:', error);
        throw error;
    }
};

// Obtenir la liste des administrateurs d'une entreprise
export const getEntrepriseAdmins = async (entrepriseId) => {
    const result = await pool.query(
        `SELECT 
            u.user_id,
            u.username,
            u.email,
            u.role,
            u.created_at,
            u.two_factor_enabled
        FROM users u
        WHERE u.entreprise_id = $1 AND u.role = 'admin'
        ORDER BY u.created_at DESC`,
        [entrepriseId]
    );
    
    return result.rows;
};

// Obtenir la liste des contributeurs d'une entreprise
export const getEntrepriseContributeurs = async (entrepriseId) => {
    const result = await pool.query(
        `SELECT 
            u.user_id,
            u.username,
            u.email,
            u.role,
            u.created_at,
            u.two_factor_enabled
        FROM users u
        WHERE u.entreprise_id = $1 AND u.role = 'contributeur'
        ORDER BY u.created_at DESC`,
        [entrepriseId]
    );
    
    return result.rows;
};

// Obtenir la liste des lecteurs d'une entreprise
export const getEntrepriseLecteurs = async (entrepriseId) => {
    const result = await pool.query(
        `SELECT 
            u.user_id,
            u.username,
            u.email,
            u.role,
            u.created_at,
            u.two_factor_enabled
        FROM users u
        WHERE u.entreprise_id = $1 AND u.role = 'lecteur'
        ORDER BY u.created_at DESC`,
        [entrepriseId]
    );
    
    return result.rows;
};

// Obtenir les statistiques détaillées des armoires
export const getArmoiresStats = async (entrepriseId) => {
    const result = await pool.query(
        `SELECT 
            a.armoire_id,
            a.nom as nom_armoire,
            a.sous_titre as description,
            a.created_at as date_creation,
            COUNT(c.cassier_id) as nombre_casiers,
            COUNT(d.dossier_id) as nombre_dossiers,
            COUNT(f.fichier_id) as nombre_fichiers,
            COALESCE(SUM(f.taille), 0) as taille_totale
        FROM armoires a
        LEFT JOIN casiers c ON a.armoire_id = c.armoire_id
        LEFT JOIN dossiers d ON c.cassier_id = d.cassier_id
        LEFT JOIN fichiers f ON d.dossier_id = f.dossier_id
        WHERE a.entreprise_id = $1
        GROUP BY a.armoire_id, a.nom, a.sous_titre, a.created_at
        ORDER BY a.created_at DESC`,
        [entrepriseId]
    );
    
    return result.rows;
};

// Obtenir les statistiques d'activité récente
export const getActiviteRecente = async (entrepriseId, limit = 10) => {
    const result = await pool.query(
        `SELECT 
            'fichier' as type_activite,
            f.nom as nom_element,
            f.created_at as date_activite,
            u.username as nom_utilisateur
        FROM fichiers f
        JOIN dossiers d ON f.dossier_id = d.dossier_id
        JOIN casiers c ON d.cassier_id = c.cassier_id
        JOIN armoires a ON c.armoire_id = a.armoire_id
        JOIN users u ON d.user_id = u.user_id
        WHERE a.entreprise_id = $1
        
        UNION ALL
        
        SELECT 
            'dossier' as type_activite,
            d.nom as nom_element,
            d.created_at as date_activite,
            u.username as nom_utilisateur
        FROM dossiers d
        JOIN casiers c ON d.cassier_id = c.cassier_id
        JOIN armoires a ON c.armoire_id = a.armoire_id
        JOIN users u ON d.user_id = u.user_id
        WHERE a.entreprise_id = $1
        
        UNION ALL
        
        SELECT 
            'casier' as type_activite,
            c.nom as nom_element,
            c.created_at as date_activite,
            u.username as nom_utilisateur
        FROM casiers c
        JOIN armoires a ON c.armoire_id = a.armoire_id
        JOIN users u ON c.user_id = u.user_id
        WHERE a.entreprise_id = $1
        
        ORDER BY date_activite DESC
        LIMIT $2`,
        [entrepriseId, limit]
    );
    
    return result.rows;
};

// Obtenir les statistiques par type de fichier
export const getStatsParTypeFichier = async (entrepriseId) => {
    const result = await pool.query(
        `SELECT 
            CASE 
                WHEN f.nom LIKE '%.pdf' THEN 'PDF'
                WHEN f.nom LIKE '%.doc%' THEN 'Word'
                WHEN f.nom LIKE '%.xls%' THEN 'Excel'
                WHEN f.nom LIKE '%.ppt%' THEN 'PowerPoint'
                WHEN f.nom LIKE '%.jpg%' OR f.nom LIKE '%.jpeg%' OR f.nom LIKE '%.png%' THEN 'Images'
                WHEN f.nom LIKE '%.txt%' THEN 'Texte'
                ELSE 'Autres'
            END as type_fichier,
            COUNT(*) as nombre_fichiers,
            COALESCE(SUM(f.taille), 0) as taille_totale
        FROM fichiers f
        JOIN dossiers d ON f.dossier_id = d.dossier_id
        JOIN casiers c ON d.cassier_id = c.cassier_id
        JOIN armoires a ON c.armoire_id = a.armoire_id
        WHERE a.entreprise_id = $1
        GROUP BY type_fichier
        ORDER BY nombre_fichiers DESC`,
        [entrepriseId]
    );
    
    return result.rows;
};

// Obtenir les statistiques de croissance mensuelle
export const getCroissanceMensuelle = async (entrepriseId, mois = 12) => {
    try {
        const result = await pool.query(
            `SELECT 
                DATE_TRUNC('month', f.created_at) as mois,
                COUNT(*) as nouveaux_fichiers,
                COALESCE(SUM(f.taille), 0) as taille_ajoutee
            FROM fichiers f
            JOIN dossiers d ON f.dossier_id = d.dossier_id
            JOIN casiers c ON d.cassier_id = c.cassier_id
            JOIN armoires a ON c.armoire_id = a.armoire_id
            WHERE a.entreprise_id = $1 
            AND f.created_at >= NOW() - INTERVAL '1 month' * $2
            GROUP BY DATE_TRUNC('month', f.created_at)
            ORDER BY mois DESC`,
            [entrepriseId, mois]
        );
        
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques de croissance:', error);
        throw error;
    }
};

// Obtenir les statistiques globales (toutes entreprises)
export const getStatsGlobalesData = async () => {
    try {
        const result = await pool.query(
            `SELECT 
                (SELECT COUNT(*) FROM entreprises) as nombre_entreprises,
                (SELECT COUNT(*) FROM users) as nombre_utilisateurs_total,
                (SELECT COUNT(*) FROM armoires) as nombre_armoires_total,
                (SELECT COUNT(*) FROM casiers) as nombre_casiers_total,
                (SELECT COUNT(*) FROM dossiers) as nombre_dossiers_total,
                (SELECT COUNT(*) FROM fichiers) as nombre_fichiers_total,
                (SELECT COALESCE(SUM(taille), 0) FROM fichiers) as taille_totale_globale
            `
        );
        
        return result.rows[0] || {
            nombre_entreprises: 0,
            nombre_utilisateurs_total: 0,
            nombre_armoires_total: 0,
            nombre_casiers_total: 0,
            nombre_dossiers_total: 0,
            nombre_fichiers_total: 0,
            taille_totale_globale: 0
        };
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques globales:', error);
        throw error;
    }
};

// Obtenir tous les logs d'activité d'une entreprise
export const getLogsEntreprise = async (entrepriseId, limit = 100, offset = 0) => {
    try {
        const logs = await getEntrepriseLogs(entrepriseId, limit, offset);
        return logs;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        throw error;
    }
};

// Obtenir les statistiques des logs d'une entreprise
export const getLogsStats = async (entrepriseId) => {
    try {
        const result = await pool.query(
            `SELECT 
                COUNT(*) as nombre_total_logs,
                COUNT(DISTINCT ja.user_id) as nombre_utilisateurs_actifs,
                COUNT(CASE WHEN ja.action = 'create' THEN 1 END) as nombre_creations,
                COUNT(CASE WHEN ja.action = 'update' THEN 1 END) as nombre_modifications,
                COUNT(CASE WHEN ja.action = 'delete' THEN 1 END) as nombre_suppressions,
                COUNT(CASE WHEN ja.action = 'login' THEN 1 END) as nombre_connexions,
                COUNT(CASE WHEN ja.type_cible = 'file' THEN 1 END) as nombre_actions_fichiers,
                COUNT(CASE WHEN ja.type_cible = 'folder' THEN 1 END) as nombre_actions_dossiers,
                COUNT(CASE WHEN ja.type_cible = 'armoire' THEN 1 END) as nombre_actions_armoires,
                COUNT(CASE WHEN ja.type_cible = 'casier' THEN 1 END) as nombre_actions_casiers,
                MIN(ja.created_at) as premiere_action,
                MAX(ja.created_at) as derniere_action
            FROM journal_activite ja
            JOIN users u ON ja.user_id = u.user_id
            WHERE u.entreprise_id = $1`,
            [entrepriseId]
        );
        
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques des logs:', error);
        throw error;
    }
};

// Obtenir les logs par utilisateur dans une entreprise
export const getLogsParUtilisateur = async (entrepriseId, limit = 50) => {
    try {
        const result = await pool.query(
            `SELECT 
                u.user_id,
                u.username,
                u.email,
                u.role,
                COUNT(ja.log_id) as nombre_actions,
                COUNT(CASE WHEN ja.action = 'create' THEN 1 END) as nombre_creations,
                COUNT(CASE WHEN ja.action = 'update' THEN 1 END) as nombre_modifications,
                COUNT(CASE WHEN ja.action = 'delete' THEN 1 END) as nombre_suppressions,
                COUNT(CASE WHEN ja.action = 'login' THEN 1 END) as nombre_connexions,
                MAX(ja.created_at) as derniere_action
            FROM users u
            LEFT JOIN journal_activite ja ON u.user_id = ja.user_id
            WHERE u.entreprise_id = $1
            GROUP BY u.user_id, u.username, u.email, u.role
            ORDER BY nombre_actions DESC
            LIMIT $2`,
            [entrepriseId, limit]
        );
        
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par utilisateur:', error);
        throw error;
    }
};

// Obtenir les logs par type d'action dans une entreprise
export const getLogsParAction = async (entrepriseId) => {
    try {
        const result = await pool.query(
            `SELECT 
                ja.action,
                COUNT(*) as nombre_actions,
                COUNT(DISTINCT ja.user_id) as nombre_utilisateurs_uniques,
                MIN(ja.created_at) as premiere_action,
                MAX(ja.created_at) as derniere_action
            FROM journal_activite ja
            JOIN users u ON ja.user_id = u.user_id
            WHERE u.entreprise_id = $1
            GROUP BY ja.action
            ORDER BY nombre_actions DESC`,
            [entrepriseId]
        );
        
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par action:', error);
        throw error;
    }
};

// Obtenir les logs par type de cible dans une entreprise
export const getLogsParCible = async (entrepriseId) => {
    try {
        const result = await pool.query(
            `SELECT 
                ja.type_cible,
                COUNT(*) as nombre_actions,
                COUNT(DISTINCT ja.user_id) as nombre_utilisateurs_uniques,
                MIN(ja.created_at) as premiere_action,
                MAX(ja.created_at) as derniere_action
            FROM journal_activite ja
            JOIN users u ON ja.user_id = u.user_id
            WHERE u.entreprise_id = $1
            GROUP BY ja.type_cible
            ORDER BY nombre_actions DESC`,
            [entrepriseId]
        );
        
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par cible:', error);
        throw error;
    }
}; 