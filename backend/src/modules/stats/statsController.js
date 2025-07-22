import {
    getEntrepriseStats,
    getEntrepriseAdmins,
    getEntrepriseContributeurs,
    getEntrepriseLecteurs,
    getArmoiresStats,
    getActiviteRecente,
    getStatsParTypeFichier,
    getCroissanceMensuelle,
    getStatsGlobalesData,
    getLogsEntreprise,
    getLogsStats,
    getLogsParUtilisateur,
    getLogsParAction,
    getLogsParCible
} from './statsModels.js';

// Obtenir les statistiques générales d'une entreprise
export const getStats = async (req, res) => {
    try {
        const stats = await getEntrepriseStats(req.params.id);
        
        if (!stats) {
            return res.status(404).json({ message: 'Entreprise non trouvée' });
        }
        
        // Formater la taille des fichiers en MB pour plus de lisibilité
        stats.taille_totale_fichiers_mb = (stats.taille_totale_fichiers / (1024 * 1024)).toFixed(2);
        
        res.json(stats);
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques' });
    }
};

// Obtenir la liste des administrateurs d'une entreprise
export const getAdmins = async (req, res) => {
    try {
        const admins = await getEntrepriseAdmins(req.params.id);
        res.json({
            message: 'Liste des administrateurs récupérée avec succès',
            data: admins,
            count: admins.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des administrateurs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des administrateurs' });
    }
};

// Obtenir la liste des contributeurs d'une entreprise
export const getContributeurs = async (req, res) => {
    try {
        const contributeurs = await getEntrepriseContributeurs(req.params.id);
        res.json({
            message: 'Liste des contributeurs récupérée avec succès',
            data: contributeurs,
            count: contributeurs.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des contributeurs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des contributeurs' });
    }
};

// Obtenir la liste des lecteurs d'une entreprise
export const getLecteurs = async (req, res) => {
    try {
        const lecteurs = await getEntrepriseLecteurs(req.params.id);
        res.json({
            message: 'Liste des lecteurs récupérée avec succès',
            data: lecteurs,
            count: lecteurs.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des lecteurs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des lecteurs' });
    }
};

// Obtenir les statistiques détaillées des armoires
export const getStatsArmoires = async (req, res) => {
    try {
        const armoiresStats = await getArmoiresStats(req.params.id);
        
        // Formater la taille en MB pour chaque armoire
        const formattedStats = armoiresStats.map(armoire => ({
            ...armoire,
            taille_totale_mb: (armoire.taille_totale / (1024 * 1024)).toFixed(2)
        }));
        
        res.json({
            message: 'Statistiques des armoires récupérées avec succès',
            data: formattedStats,
            count: formattedStats.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques des armoires:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques des armoires' });
    }
};

// Obtenir l'activité récente
export const getActivite = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 10;
        const activite = await getActiviteRecente(req.params.id, limit);
        
        res.json({
            message: 'Activité récente récupérée avec succès',
            data: activite,
            count: activite.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'activité récente:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération de l\'activité récente' });
    }
};

// Obtenir les statistiques par type de fichier
export const getStatsTypesFichiers = async (req, res) => {
    try {
        const statsTypes = await getStatsParTypeFichier(req.params.id);
        
        // Formater la taille en MB pour chaque type
        const formattedStats = statsTypes.map(type => ({
            ...type,
            taille_totale_mb: (type.taille_totale / (1024 * 1024)).toFixed(2)
        }));
        
        res.json({
            message: 'Statistiques par type de fichier récupérées avec succès',
            data: formattedStats,
            count: formattedStats.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques par type de fichier:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques par type de fichier' });
    }
};

// Obtenir les statistiques de croissance mensuelle
export const getCroissance = async (req, res) => {
    try {
        const mois = parseInt(req.query.mois) || 12;
        const croissance = await getCroissanceMensuelle(req.params.id, mois);
        
        // Formater la taille en MB et ajouter le mois formaté
        const formattedCroissance = croissance.map(item => ({
            ...item,
            mois_formate: new Date(item.mois).toLocaleDateString('fr-FR', { 
                year: 'numeric', 
                month: 'long' 
            }),
            taille_ajoutee_mb: (item.taille_ajoutee / (1024 * 1024)).toFixed(2)
        }));
        
        res.json({
            message: 'Statistiques de croissance récupérées avec succès',
            data: formattedCroissance,
            count: formattedCroissance.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques de croissance:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques de croissance' });
    }
};

// Obtenir les statistiques globales (admin seulement)
export const getStatsGlobales = async (req, res) => {
    try {
        const statsGlobales = await getStatsGlobalesData();
        
        if (!statsGlobales) {
            return res.status(500).json({ 
                message: 'Erreur lors de la récupération des statistiques globales: données non disponibles' 
            });
        }
        
        // Formater la taille en GB pour les statistiques globales
        const taille_totale_globale = statsGlobales.taille_totale_globale || 0;
        statsGlobales.taille_totale_globale_gb = (taille_totale_globale / (1024 * 1024 * 1024)).toFixed(2);
        
        res.json({
            message: 'Statistiques globales récupérées avec succès',
            data: statsGlobales
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques globales:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques globales' });
    }
};

// Obtenir un tableau de bord complet pour une entreprise
export const getTableauBord = async (req, res) => {
    try {
        const entrepriseId = req.params.id;
        
        // Récupérer toutes les statistiques en parallèle
        const [
            statsGenerales,
            admins,
            contributeurs,
            lecteurs,
            armoiresStats,
            activiteRecente,
            statsTypes,
            croissance
        ] = await Promise.all([
            getEntrepriseStats(entrepriseId),
            getEntrepriseAdmins(entrepriseId),
            getEntrepriseContributeurs(entrepriseId),
            getEntrepriseLecteurs(entrepriseId),
            getArmoiresStats(entrepriseId),
            getActiviteRecente(entrepriseId, 5),
            getStatsParTypeFichier(entrepriseId),
            getCroissanceMensuelle(entrepriseId, 6)
        ]);
        
        // Formater les données
        const tableauBord = {
            stats_generales: {
                ...statsGenerales,
                taille_totale_fichiers_mb: (statsGenerales.taille_totale_fichiers / (1024 * 1024)).toFixed(2)
            },
            utilisateurs: {
                admins: {
                    data: admins,
                    count: admins.length
                },
                contributeurs: {
                    data: contributeurs,
                    count: contributeurs.length
                },
                lecteurs: {
                    data: lecteurs,
                    count: lecteurs.length
                }
            },
            armoires: {
                data: armoiresStats.map(armoire => ({
                    ...armoire,
                    taille_totale_mb: (armoire.taille_totale / (1024 * 1024)).toFixed(2)
                })),
                count: armoiresStats.length
            },
            activite_recente: {
                data: activiteRecente,
                count: activiteRecente.length
            },
            types_fichiers: {
                data: statsTypes.map(type => ({
                    ...type,
                    taille_totale_mb: (type.taille_totale / (1024 * 1024)).toFixed(2)
                })),
                count: statsTypes.length
            },
            croissance: {
                data: croissance.map(item => ({
                    ...item,
                    mois_formate: new Date(item.mois).toLocaleDateString('fr-FR', { 
                        year: 'numeric', 
                        month: 'long' 
                    }),
                    taille_ajoutee_mb: (item.taille_ajoutee / (1024 * 1024)).toFixed(2)
                })),
                count: croissance.length
            }
        };
        
        res.json({
            message: 'Tableau de bord récupéré avec succès',
            data: tableauBord
        });
    } catch (error) {
        console.error('Erreur lors de la récupération du tableau de bord:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération du tableau de bord' });
    }
};

// Obtenir tous les logs d'activité d'une entreprise
export const getLogs = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        const offset = parseInt(req.query.offset) || 0;
        
        const logs = await getLogsEntreprise(req.params.id, limit, offset);
        
        res.json({
            message: 'Logs d\'activité récupérés avec succès',
            data: logs,
            count: logs.length,
            pagination: {
                limit,
                offset,
                has_more: logs.length === limit
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des logs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs' });
    }
};

// Obtenir les statistiques des logs d'une entreprise
export const getLogsStatsController = async (req, res) => {
    try {
        const logsStats = await getLogsStats(req.params.id);
        
        res.json({
            message: 'Statistiques des logs récupérées avec succès',
            data: logsStats
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques des logs:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des statistiques des logs' });
    }
};

// Obtenir les logs par utilisateur dans une entreprise
export const getLogsParUtilisateurController = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const logsParUtilisateur = await getLogsParUtilisateur(req.params.id, limit);
        
        res.json({
            message: 'Logs par utilisateur récupérés avec succès',
            data: logsParUtilisateur,
            count: logsParUtilisateur.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par utilisateur:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs par utilisateur' });
    }
};

// Obtenir les logs par type d'action dans une entreprise
export const getLogsParActionController = async (req, res) => {
    try {
        const logsParAction = await getLogsParAction(req.params.id);
        
        res.json({
            message: 'Logs par action récupérés avec succès',
            data: logsParAction,
            count: logsParAction.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par action:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs par action' });
    }
};

// Obtenir les logs par type de cible dans une entreprise
export const getLogsParCibleController = async (req, res) => {
    try {
        const logsParCible = await getLogsParCible(req.params.id);
        
        res.json({
            message: 'Logs par cible récupérés avec succès',
            data: logsParCible,
            count: logsParCible.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des logs par cible:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des logs par cible' });
    }
};

// Obtenir un tableau de bord complet avec logs pour une entreprise
export const getTableauBordComplet = async (req, res) => {
    try {
        const entrepriseId = req.params.id;
        
        // Récupérer toutes les statistiques et logs en parallèle
        const [
            statsGenerales,
            admins,
            contributeurs,
            lecteurs,
            armoiresStats,
            activiteRecente,
            statsTypes,
            croissance,
            logsStats,
            logsParUtilisateur,
            logsParAction,
            logsParCible
        ] = await Promise.all([
            getEntrepriseStats(entrepriseId),
            getEntrepriseAdmins(entrepriseId),
            getEntrepriseContributeurs(entrepriseId),
            getEntrepriseLecteurs(entrepriseId),
            getArmoiresStats(entrepriseId),
            getActiviteRecente(entrepriseId, 5),
            getStatsParTypeFichier(entrepriseId),
            getCroissanceMensuelle(entrepriseId, 6),
            getLogsStats(entrepriseId),
            getLogsParUtilisateur(entrepriseId, 10),
            getLogsParAction(entrepriseId),
            getLogsParCible(entrepriseId)
        ]);
        
        // Formater les données
        const tableauBordComplet = {
            stats_generales: {
                ...statsGenerales,
                taille_totale_fichiers_mb: (statsGenerales.taille_totale_fichiers / (1024 * 1024)).toFixed(2)
            },
            utilisateurs: {
                admins: {
                    data: admins,
                    count: admins.length
                },
                contributeurs: {
                    data: contributeurs,
                    count: contributeurs.length
                },
                lecteurs: {
                    data: lecteurs,
                    count: lecteurs.length
                }
            },
            armoires: {
                data: armoiresStats.map(armoire => ({
                    ...armoire,
                    taille_totale_mb: (armoire.taille_totale / (1024 * 1024)).toFixed(2)
                })),
                count: armoiresStats.length
            },
            activite_recente: {
                data: activiteRecente,
                count: activiteRecente.length
            },
            types_fichiers: {
                data: statsTypes.map(type => ({
                    ...type,
                    taille_totale_mb: (type.taille_totale / (1024 * 1024)).toFixed(2)
                })),
                count: statsTypes.length
            },
            croissance: {
                data: croissance.map(item => ({
                    ...item,
                    mois_formate: new Date(item.mois).toLocaleDateString('fr-FR', { 
                        year: 'numeric', 
                        month: 'long' 
                    }),
                    taille_ajoutee_mb: (item.taille_ajoutee / (1024 * 1024)).toFixed(2)
                })),
                count: croissance.length
            },
            logs: {
                statistiques: logsStats,
                par_utilisateur: {
                    data: logsParUtilisateur,
                    count: logsParUtilisateur.length
                },
                par_action: {
                    data: logsParAction,
                    count: logsParAction.length
                },
                par_cible: {
                    data: logsParCible,
                    count: logsParCible.length
                }
            }
        };
        
        res.json({
            message: 'Tableau de bord complet récupéré avec succès',
            data: tableauBordComplet
        });
    } catch (error) {
        console.error('Erreur lors de la récupération du tableau de bord complet:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération du tableau de bord complet' });
    }
}; 