import { logAction } from '../audit/auditService.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { v4 as uuidv4 } from 'uuid';
import versionModel from './versionModel.js';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin de stockage des versions
const VERSIONS_STORAGE_DIR = path.join(__dirname, '../../../../uploads/versions');

// S'assurer que le répertoire existe
if (!fs.existsSync(VERSIONS_STORAGE_DIR)) {
    fs.mkdirSync(VERSIONS_STORAGE_DIR, { recursive: true });
}

class VersionService {
    async createNewVersion(cibleId, content, versionMetadata, utilisateur_id) {
        try {
            const versionId = uuidv4();
            const cibleVersionDir = path.join(VERSIONS_STORAGE_DIR, cibleId.toString());
            const versionContentPath = path.join(cibleVersionDir, `${versionId}_content`);

            // Assurer que le répertoire existe
            if (!fs.existsSync(cibleVersionDir)) {
                fs.mkdirSync(cibleVersionDir, { recursive: true });
            }

            // Stocker le contenu
            await fs.promises.writeFile(versionContentPath, content);

            // Insérer la nouvelle version dans la base de données
            const newVersion = await versionModel.createVersion({
                id: versionId,
                cible_id: cibleId,
                type: versionMetadata.type,
                version_number: versionMetadata.version_number,
                storage_path: versionContentPath,
                metadata: versionMetadata,
                created_by: utilisateur_id
            });

            // Journaliser l'action
            if (utilisateur_id) {
                await logAction(
                    utilisateur_id,
                    'create_version',
                    'version',
                    versionId,
                    {
                        version_id: versionId,
                        type: versionMetadata.type,
                        date: new Date()
                    }
                );
            }

            return newVersion;

        } catch (error) {
            // Nettoyer le fichier temporaire si l'insertion DB échoue
            if (versionContentPath && fs.existsSync(versionContentPath)) {
                await fs.promises.unlink(versionContentPath);
            }
            throw error;
        }
    }

    async getVersionHistory(cibleId) {
        return await versionModel.getVersionsByCibleId(cibleId);
    }

    async getVersionContent(versionId) {
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
    }

    async deleteVersion(versionId, utilisateur_id) {
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
                    cible_id: version.cible_id,
                    version_number: version.version_number,
                },
                new Date()
            );
        }

        return deletedVersion;
    }

    async compareVersions(versionId1, versionId2) {
        const [version1, version2] = await Promise.all([
            this.getVersionContent(versionId1),
            this.getVersionContent(versionId2)
        ]);

        // Comparer les métadonnées
        const metadataDiff = this.compareMetadata(version1.metadata, version2.metadata);

        // Comparer le contenu
        const contentDiff = version1.content.equals(version2.content) ? null : 'Contenu différent';

        return {
            metadataDiff,
            contentDiff
        };
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
}

export default new VersionService(); 