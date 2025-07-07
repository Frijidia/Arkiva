import versionService from './versionService.js';
import { logAction } from '../audit/auditService.js';

//import { downloadFileBufferFromS3 } from '../fichiers/fichierControllers.js';

// Créer une nouvelle version
export const createVersion = async (req, res) => {
    try {
        console.log('Requête reçue pour création de version :', req.body);
        const { cible_id, type, version_number, description } = req.body;
        const utilisateur_id = req.user.user_id;

        if (!cible_id || !type) {
            return res.status(400).json({
                error: 'cible_id et type sont requis',
                message: 'Veuillez fournir cible_id et type dans le corps de la requête'
            });
        }

        // Valider le type
        const validTypes = ['fichier', 'dossier', 'casier', 'armoire'];
        if (!validTypes.includes(type)) {
            return res.status(400).json({
                error: 'Type invalide',
                message: 'Le type doit être l\'un des suivants: fichier, dossier, casier, armoire'
            });
        }

        // Récupérer les détails de la cible selon le type
        let details, content, versionMetadata;

        switch (type) {
            case 'fichier':
                // TODO: Implémenter la récupération des détails de fichier
                details = {
                    id: cible_id,
                    name: `fichier_${cible_id}`,
                    version_number: 1
                };
                content = 'Contenu simulé du fichier';
                versionMetadata = {
                    version_number: version_number || (details.version_number || 0) + 1,
                    description: description || "Description de la version",
                    type: 'fichier',
                    original_name: details.name,
                    size: content.length
                };
                break;

            case 'dossier':
                // TODO: Implémenter la récupération des détails de dossier
                details = {
                    id: cible_id,
                    name: `dossier_${cible_id}`,
                    version_number: 1
                };
                content = { name: details.name, files: [] };
                versionMetadata = {
                    version_number: version_number || (details.version_number || 0) + 1,
                    description: description || "Description de la version",
                    type: 'dossier',
                    original_name: details.name
                };
                break;

            case 'casier':
                // TODO: Implémenter la récupération des détails de casier
                details = {
                    id: cible_id,
                    name: `casier_${cible_id}`,
                    version_number: 1
                };
                content = { name: details.name, dossiers: [] };
                versionMetadata = {
                    version_number: version_number || (details.version_number || 0) + 1,
                    description: description || "Description de la version",
                    type: 'casier',
                    original_name: details.name
                };
                break;

            case 'armoire':
                // TODO: Implémenter la récupération des détails d'armoire
                details = {
                    id: cible_id,
                    name: `armoire_${cible_id}`,
                    version_number: 1
                };
                content = { name: details.name, casiers: [] };
                versionMetadata = {
                    version_number: version_number || (details.version_number || 0) + 1,
                    description: description || "Description de la version",
                    type: 'armoire',
                    original_name: details.name
                };
                break;

            default:
                return res.status(400).json({
                    error: 'Type non supporté',
                    message: 'Le type fourni n\'est pas supporté'
                });
        }

        const version = await versionService.createNewVersion(
            cible_id,
            type,
            content,
            versionMetadata,
            utilisateur_id
        );

        res.status(201).json(version);
    } catch (error) {
        console.error('Erreur lors de la création de la version:', error);
        res.status(500).json({
            error: 'Erreur lors de la création de la version',
            details: error.message
        });
    }
};

// Obtenir l'historique des versions
export const getVersionHistory = async (req, res) => {
    try {
        console.log('Requête reçue pour historique des versions :', req.query);
        const { cible_id, type } = req.query;

        if (!cible_id || !type) {
            return res.status(400).json({
                error: 'cible_id et type sont requis',
                message: 'Veuillez fournir cible_id et type dans les paramètres de requête'
            });
        }

        // Valider le type
        const validTypes = ['fichier', 'dossier', 'casier', 'armoire'];
        if (!validTypes.includes(type)) {
            return res.status(400).json({
                error: 'Type invalide',
                message: 'Le type doit être l\'un des suivants: fichier, dossier, casier, armoire'
            });
        }

        const history = await versionService.getVersionHistory(cible_id, type);

        res.json({
            cible_id,
            type,
            versions: history,
            total: history.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'historique:', error);
        res.status(500).json({
            error: 'Erreur lors de la récupération de l\'historique',
            details: error.message
        });
    }
};

// Obtenir le contenu d'une version
export const getVersionContent = async (req, res) => {
    try {
        const version = await versionService.getVersionContent(req.params.id);
        if (!version) {
            return res.status(404).json({ error: 'Version non trouvée' });
        }
        res.json(version);
    } catch (error) {
        console.error('Erreur lors de la récupération du contenu:', error);
        res.status(500).json({
            error: 'Erreur lors de la récupération du contenu',
            details: error.message
        });
    }
};

// Obtenir une URL de téléchargement signée pour une version
export const getVersionDownloadUrl = async (req, res) => {
    try {
        const { expiresIn = 3600 } = req.query; // 1 heure par défaut
        const versionId = req.params.id;

        const downloadUrl = await versionService.getVersionDownloadUrl(versionId, parseInt(expiresIn));
        
        if (!downloadUrl) {
            return res.status(404).json({ error: 'Version non trouvée' });
        }

        res.json({
            version_id: versionId,
            download_url: downloadUrl,
            expires_in: expiresIn
        });
    } catch (error) {
        console.error('Erreur lors de la génération de l\'URL de téléchargement:', error);
        res.status(500).json({
            error: 'Erreur lors de la génération de l\'URL de téléchargement',
            details: error.message
        });
    }
};

// Comparer deux versions
export const compareVersions = async (req, res) => {
    try {
        const { versionId1, versionId2 } = req.body;

        if (!versionId1 || !versionId2) {
            return res.status(400).json({
                error: 'Les deux IDs de version sont requis',
                message: 'Veuillez fournir versionId1 et versionId2 dans le corps de la requête'
            });
        }

        const comparison = await versionService.compareVersions(versionId1, versionId2);

        if (!comparison) {
            return res.status(404).json({ error: 'Une ou plusieurs versions non trouvées' });
        }

        res.json(comparison);
    } catch (error) {
        console.error('Erreur lors de la comparaison des versions:', error);
        res.status(500).json({
            error: 'Erreur lors de la comparaison des versions',
            details: error.message
        });
    }
};

// Supprimer une version
export const deleteVersion = async (req, res) => {
    try {
        const result = await versionService.deleteVersion(req.params.id, req.user.user_id);
        if (!result) {
            return res.status(404).json({ error: 'Version non trouvée' });
        }
        res.json({ message: 'Version supprimée avec succès', version: result });
    } catch (error) {
        console.error('Erreur lors de la suppression de la version:', error);
        res.status(500).json({
            error: 'Erreur lors de la suppression de la version',
            details: error.message
        });
    }
}; 