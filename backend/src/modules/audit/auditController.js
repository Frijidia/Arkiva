//import "./auditModels.js"
import { getUserLogs, getTargetLogs, getEntrepriseLogs } from './auditService.js';
// Obtenir les logs d'un utilisateur

export const getUserActivity = async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        const logs = await getUserLogs(req.params.userId, parseInt(limit), parseInt(offset));
        res.json(logs);
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs' });
    }
};

// Obtenir les logs d'une cible spécifique
export const getTargetActivity = async (req, res) => {
    try {
        const { type, id } = req.params;
        const { limit = 50, offset = 0 } = req.query;
        const logs = await getTargetLogs(type, id, parseInt(limit), parseInt(offset));
        res.json(logs);
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs' });
    }
};

// Obtenir les logs d'une entreprise
export const getEntrepriseActivity = async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        const logs = await getEntrepriseLogs(req.params.entrepriseId, parseInt(limit), parseInt(offset));
        res.json(logs);
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs' });
    }
}; 