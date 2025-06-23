import versionService from './versionService.js';
import * as fileModel from '../fichiers/fichierModels.js';
import * as dossierModel from '../dosiers/dosierModels.js';
import * as casierModel from '../cassiers/cassierModels.js';
import * as armoireModel from '../armoires/armoireModels.js';
import { downloadFileBufferFromS3 } from '../fichiers/fichierControllers.js';
import pool from '../../config/database.js';

// Fonction utilitaire pour vérifier l'existence et le type d'un élément
async function verifyElementExists(targetId, type) {
    let exists = false;
    let actualType = null;

    // Vérifier dans chaque service
    const fileDetails = await fileModel.getFileDetails(targetId);
    if (fileDetails) {
        exists = true;
        actualType = 'fichier';
    }

    const dossierDetails = await dossierModel.getDossierDetails(targetId);
    if (dossierDetails) {
        if (exists) {
            throw new Error(`L'ID ${targetId} existe à la fois comme fichier et comme dossier`);
        }
        exists = true;
        actualType = 'dossier';
    }

    const casierDetails = await casierModel.getCasierDetails(targetId);
    if (casierDetails) {
        if (exists) {
            throw new Error(`L'ID ${targetId} existe à la fois comme ${actualType} et comme casier`);
        }
        exists = true;
        actualType = 'casier';
    }

    const armoireDetails = await armoireModel.getArmoireDetails(targetId);
    if (armoireDetails) {
        if (exists) {
            throw new Error(`L'ID ${targetId} existe à la fois comme ${actualType} et comme armoire`);
        }
        exists = true;
        actualType = 'armoire';
    }

    if (!exists) {
        throw new Error(`Aucun élément trouvé avec l'ID ${targetId}`);
    }

    if (type && actualType !== type) {
        throw new Error(`L'élément avec l'ID ${targetId} est de type ${actualType}, mais vous avez spécifié ${type}`);
    }

    return actualType;
}

// Créer une nouvelle version
export const createVersion = async (req, res) => {
    try {
        const { 
            cible,  // Nouvelle structure pour la cible
            version_number,
            metadata = {}
        } = req.body;

        // Validation de la structure de la cible
        if (!cible || !cible.id || !cible.type) {
            return res.status(400).json({
                error: 'Structure de cible invalide',
                message: 'La cible doit avoir la structure suivante : { id: "ID", type: "type" }',
                example: {
                    cible: {
                        id: "1",
                        type: "fichier" // ou "dossier", "casier", "armoire"
                    },
                    version_number: "1.0",
                    metadata: {
                        description: "Description de la version"
                    }
                }
            });
        }

        const { id: targetId, type } = cible;

        if (!['fichier', 'dossier', 'casier', 'armoire'].includes(type)) {
            return res.status(400).json({
                error: 'Type de cible invalide',
                message: 'Le type doit être l\'un des suivants : fichier, dossier, casier, armoire'
            });
        }

        let details, content, versionMetadata;

        switch(type) {
            case 'fichier':
                const fileResult = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [targetId]);
                if (fileResult.rows.length === 0) {
                    return res.status(404).json({ error: 'Fichier non trouvé' });
                }
                details = fileResult.rows[0];
                
                // Récupérer le contenu du fichier depuis S3
                const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';
                const key = details.chemin.replace(s3BaseUrl, '');
                content = await downloadFileBufferFromS3(key);
                
                versionMetadata = {
                    nom: details.nom,
                    type_mime: details.type_mime,
                    taille: details.taille,
                    version_number: version_number || (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date(),
                    ...metadata
                };
                break;

            case 'dossier':
                const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [targetId]);
                if (dossierResult.rows.length === 0) {
                    return res.status(404).json({ error: 'Dossier non trouvé' });
                }
                details = dossierResult.rows[0];
                
                // Récupérer le contenu du dossier (liste des fichiers)
                const fichiersResult = await pool.query(
                    'SELECT * FROM fichiers WHERE dossier_id = $1',
                    [targetId]
                );
                content = fichiersResult.rows;
                
                versionMetadata = {
                    nom: details.nom,
                    type: "dossier",
                    nombre_elements: details.nombre_elements,
                    version_number: version_number || (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date(),
                    ...metadata
                };
                break;

            case 'casier':
                const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [targetId]);
                if (casierResult.rows.length === 0) {
                    return res.status(404).json({ error: 'Casier non trouvé' });
                }
                details = casierResult.rows[0];
                
                // Récupérer le contenu du casier (liste des dossiers)
                const dossiersResult = await pool.query(
                    'SELECT * FROM dossiers WHERE casier_id = $1',
                    [targetId]
                );
                content = dossiersResult.rows;
                
                versionMetadata = {
                    nom: details.nom,
                    type: "casier",
                    nombre_elements: details.nombre_elements,
                    version_number: version_number || (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date(),
                    ...metadata
                };
                break;

            case 'armoire':
                const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [targetId]);
                if (armoireResult.rows.length === 0) {
                    return res.status(404).json({ error: 'Armoire non trouvée' });
                }
                details = armoireResult.rows[0];
                
                // Récupérer le contenu de l'armoire (liste des casiers)
                const casiersResult = await pool.query(
                    'SELECT * FROM casiers WHERE armoire_id = $1',
                    [targetId]
                );
                content = casiersResult.rows;
                
                versionMetadata = {
                    nom: details.nom,
                    type: "armoire",
                    nombre_elements: details.nombre_elements,
                    version_number: version_number || (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date(),
                    ...metadata
                };
                break;
        }

        const version = await versionService.createNewVersion(
            targetId,
            type,
            content,
            versionMetadata,
            req.user.user_id
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
        const { cible_id, type } = req.body;
        
        if (!cible_id) {
            return res.status(400).json({ error: 'cible_id est requis dans le corps de la requête' });
        }
        if (!type) {
            return res.status(400).json({ error: 'type est requis dans le corps de la requête' });
        }
        if (!['fichier', 'dossier', 'casier', 'armoire'].includes(type)) {
            return res.status(400).json({ 
                error: 'Type de cible invalide',
                message: 'Le type doit être l\'un des suivants : fichier, dossier, casier, armoire'
            });
        }

        const history = await versionService.getVersionHistory(cible_id, type);
        res.json(history);
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
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la suppression de la version:', error);
        res.status(500).json({ 
            error: 'Erreur lors de la suppression de la version',
            details: error.message 
        });
    }
}; 