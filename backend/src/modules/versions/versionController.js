import versionService from './versionService.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';

// Créer une nouvelle version
export const createVersion = async (req, res) => {
    try {
        const { cible_id, type } = req.body;
        
        let details, content, versionMetadata;

        switch(type) {
            case 'fichier':
                details = await fileService.getFileDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Fichier non trouvé' });
                }
                content = await fileService.getFileContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du fichier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type_mime: details.type_mime,
                    taille: details.taille,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'dossier':
                details = await dossierService.getDossierDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Dossier non trouvé' });
                }
                content = await dossierService.getDossierContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du dossier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "dossier",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'casier':
                details = await casierService.getCasierDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Casier non trouvé' });
                }
                content = await casierService.getCasierContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du casier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "casier",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'armoire':
                details = await armoireService.getArmoireDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Armoire non trouvée' });
                }
                content = await armoireService.getArmoireContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu de l\'armoire non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "armoire",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            default:
                return res.status(400).json({ error: 'Type de cible invalide' });
        }

        const version = await versionService.createNewVersion(
            cible_id,
            content,
            versionMetadata,
            req.user.user_id
        );

        res.status(201).json(version);
    } catch (error) {
        console.error('Erreur lors de la création de la version:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir l'historique des versions
export const getVersionHistory = async (req, res) => {
    try {
        const history = await versionService.getVersionHistory(req.params.cibleId);
        res.json(history);
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'historique:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir le contenu d'une version
export const getVersionContent = async (req, res) => {
    try {
        const version = await versionService.getVersionContent(req.params.id);
        res.json(version);
    } catch (error) {
        console.error('Erreur lors de la récupération du contenu:', error);
        res.status(500).json({ error: error.message });
    }
};

// Comparer deux versions
export const compareVersions = async (req, res) => {
    try {
        const { versionId1, versionId2 } = req.body;
        const comparison = await versionService.compareVersions(versionId1, versionId2);
        res.json(comparison);
    } catch (error) {
        console.error('Erreur lors de la comparaison des versions:', error);
        res.status(500).json({ error: error.message });
    }
};

// Supprimer une version
export const deleteVersion = async (req, res) => {
    try {
        const result = await versionService.deleteVersion(req.params.id, req.user.user_id);
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la suppression de la version:', error);
        res.status(500).json({ error: error.message });
    }
}; 