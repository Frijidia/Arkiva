import { logAction } from '../audit/auditService.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { v4 as uuidv4 } from 'uuid';
import versionModel from './versionModel.js';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Assume a storage directory for versioned files
const VERSIONS_STORAGE_DIR = path.join(__dirname, '../../../../uploads/versions'); // Ajustez ce chemin si nécessaire

// Ensure the storage directory exists
if (!fs.existsSync(VERSIONS_STORAGE_DIR)) {
    fs.mkdirSync(VERSIONS_STORAGE_DIR, { recursive: true });
}

class VersionService {
    // Cette fonction sera responsable de la création d'une nouvelle version d'un fichier existant.
    // Elle gère l'insertion dans la table des versions et le stockage physique du contenu.
    async createNewVersion(fileId, fileContent, versionMetadata, utilisateur_id) {
        console.log(`[versionService] Création d'une nouvelle version pour fichier ${fileId}`);
        
        try {
            // Générer l'UUID avant de créer le fichier
            const versionId = uuidv4();
            const fileVersionDir = path.join(VERSIONS_STORAGE_DIR, fileId.toString());
            const versionContentPath = path.join(fileVersionDir, `${versionId}_content`);

            // Assurer que le répertoire existe
            if (!fs.existsSync(fileVersionDir)) {
                fs.mkdirSync(fileVersionDir, { recursive: true });
            }

            // Stocker le contenu du fichier
            await fs.promises.writeFile(versionContentPath, fileContent);

            // Insérer la nouvelle version dans la base de données
            const newVersion = await versionModel.createVersion({
                id: versionId,
                file_id: fileId,
                version_number: versionMetadata.version_number,
                storage_path: versionContentPath,
                metadata: versionMetadata,
                created_by: utilisateur_id
            });

            console.log(`[versionService] Nouvelle version créée pour fichier ${fileId} avec ID ${versionId}`);

            // Journaliser l'action
            if (utilisateur_id) {
                await logAction(
                    utilisateur_id,
                    'create_version',
                    'version',
                    versionId,
                    {
                        version_id: versionId,
                        type: 'version',
                        date: new Date()
                    }
                );
            }

            return newVersion;

        } catch (error) {
            console.error(`[versionService] Erreur lors de la création d'une nouvelle version pour fichier ${fileId}:`, error);
            // Nettoyer le fichier temporaire si l'insertion DB échoue
            if (versionContentPath && fs.existsSync(versionContentPath)) {
                await fs.promises.unlink(versionContentPath);
            }
            throw error;
        }
    }

    // Cette fonction sera responsable de la mise à jour de la version active d'un fichier parent.
    // Elle met à jour la référence `current_version_id` dans la table `fichiers`.
    async updateFileVersion(fileId, newVersionId, utilisateur_id) {
        console.log(`[versionService] Mise à jour de la version active pour fichier ${fileId} vers version ${newVersionId}`);
        
        try {
            const updatedFile = await versionModel.updateFileVersion(fileId, newVersionId, utilisateur_id);

            if (!updatedFile) {
                throw new Error(`Fichier parent ${fileId} non trouvé pour mise à jour de version.`);
            }

            console.log(`[versionService] Version active du fichier ${fileId} mise à jour vers ${newVersionId}`);
            
            // Journaliser l'action
            if (utilisateur_id) {
                await logAction(
                    utilisateur_id,
                    'update_version',
                    'fichier',
                    fileId,
                    {
                        new_version_id: newVersionId,
                    },
                    new Date()
                );
            }

            return updatedFile;

        } catch (error) {
            console.error(`[versionService] Erreur lors de la mise à jour de la version pour fichier ${fileId}:`, error);
            throw error;
        }
    }

    async getVersionHistory(fileId) {
        try {
            return await versionModel.getVersionsByFileId(fileId);
        } catch (error) {
            console.error(`[versionService] Erreur lors de la récupération de l'historique des versions pour fichier ${fileId}:`, error);
            throw error;
        }
    }

    async getVersionContent(versionId) {
        try {
            const version = await versionModel.getVersionById(versionId);

            if (!version) {
                throw new Error(`Version ${versionId} non trouvée.`);
            }

            if (!fs.existsSync(version.storage_path)) {
                throw new Error(`Contenu de la version ${versionId} introuvable sur le disque.`);
            }

            return {
                ...version,
                content: await fs.promises.readFile(version.storage_path)
            };
        } catch (error) {
            console.error(`[versionService] Erreur lors de la récupération du contenu de la version ${versionId}:`, error);
            throw error;
        }
    }

    async deleteVersion(versionId, utilisateur_id) {
        try {
            // Récupérer les informations de la version avant de la supprimer
            const version = await this.getVersionContent(versionId);
            
            // Supprimer la version de la base de données
            const deletedVersion = await versionModel.deleteVersion(versionId);

            if (!deletedVersion) {
                throw new Error(`Version ${versionId} non trouvée.`);
            }

            // Supprimer le fichier physique
            if (fs.existsSync(version.storage_path)) {
                await fs.promises.unlink(version.storage_path);
            }

            // Journaliser l'action
            if (utilisateur_id) {
                await logAction(
                    utilisateur_id,
                    'delete_version',
                    'version',
                    versionId,
                    {
                        file_id: version.file_id,
                        version_number: version.version_number,
                    },
                    new Date()
                );
            }

            return deletedVersion;
        } catch (error) {
            console.error(`[versionService] Erreur lors de la suppression de la version ${versionId}:`, error);
            throw error;
        }
    }

    async compareVersions(versionId1, versionId2) {
        try {
            const [version1, version2] = await Promise.all([
                this.getVersionContent(versionId1),
                this.getVersionContent(versionId2)
            ]);

            // Comparer les métadonnées
            const metadataDiff = this.compareMetadata(version1.metadata, version2.metadata);

            // Comparer le contenu (si nécessaire)
            const contentDiff = version1.content.equals(version2.content) ? null : 'Contenu différent';

            return {
                metadataDiff,
                contentDiff
            };
        } catch (error) {
            console.error(`[versionService] Erreur lors de la comparaison des versions ${versionId1} et ${versionId2}:`, error);
            throw error;
        }
    }

    compareMetadata(metadata1, metadata2) {
        const diff = {};
        const allKeys = new Set([...Object.keys(metadata1), ...Object.keys(metadata2)]);

        for (const key of allKeys) {
            if (JSON.stringify(metadata1[key]) !== JSON.stringify(metadata2[key])) {
                diff[key] = {
                    old: metadata1[key],
                    new: metadata2[key]
                };
            }
        }

        return Object.keys(diff).length > 0 ? diff : null;
    }

    async logVersionAction(version, utilisateur_id) {
        if (!utilisateur_id) return;

        await logAction(
            utilisateur_id,
            'create_version',
            version.type,
            version.file_id,
            {
                version_id: version.id,
                type: version.type,
                date: new Date()
            }
        );
    }
}

export default new VersionService(); 