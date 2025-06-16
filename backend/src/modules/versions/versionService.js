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
    async createNewVersion(cibleId, type, content, versionMetadata, utilisateur_id) {
        let versionContentPath = null;
        try {
            const versionId = uuidv4();
            const cibleVersionDir = path.join(VERSIONS_STORAGE_DIR, cibleId.toString());
            versionContentPath = path.join(cibleVersionDir, `${versionId}_content`);

            // Assurer que le répertoire existe
            if (!fs.existsSync(cibleVersionDir)) {
                fs.mkdirSync(cibleVersionDir, { recursive: true });
            }

            // Convertir le contenu en Buffer si nécessaire
            let contentBuffer;
            if (Buffer.isBuffer(content)) {
                contentBuffer = content;
            } else if (typeof content === 'string') {
                contentBuffer = Buffer.from(content);
            } else if (typeof content === 'object') {
                contentBuffer = Buffer.from(JSON.stringify(content));
            } else {
                throw new Error('Type de contenu non supporté');
            }

            // Stocker le contenu
            await fs.promises.writeFile(versionContentPath, contentBuffer);

            // Insérer la nouvelle version dans la base de données
            const newVersion = await versionModel.createVersion({
                id: versionId,
                cible_id: cibleId,
                type: type,
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
                        type: type,
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

    async getVersionHistory(cibleId, type) {
        try {
            console.log('Récupération de l\'historique des versions pour cible_id:', cibleId, 'et type:', type);
            const versions = await versionModel.getVersionsByCibleId(cibleId, type);
            console.log('Versions trouvées:', versions);
            return versions;
        } catch (error) {
            console.error('Erreur lors de la récupération de l\'historique:', error);
            throw error;
        }
    }

    async getVersionContent(versionId) {
        const version = await versionModel.getVersionById(versionId);
        if (!version) {
            return null;
        }

        try {
            const content = await fs.promises.readFile(version.storage_path);
            
            // Tenter de parser le contenu comme JSON si c'est un objet
            try {
                const jsonContent = JSON.parse(content.toString());
                return {
                    ...version,
                    content: jsonContent
                };
            } catch {
                // Si ce n'est pas du JSON, retourner le contenu brut
                return {
                    ...version,
                    content: content
                };
            }
        } catch (error) {
            console.error('Erreur lors de la lecture du contenu de la version:', error);
            throw error;
        }
    }

    async deleteVersion(versionId) {
        const version = await versionModel.getVersionById(versionId);
        if (!version) {
            return null;
        }

        try {
            // Supprimer le fichier de stockage
            if (fs.existsSync(version.storage_path)) {
                await fs.promises.unlink(version.storage_path);
            }

            // Supprimer l'enregistrement de la base de données
            return await versionModel.deleteVersion(versionId);
        } catch (error) {
            console.error('Erreur lors de la suppression de la version:', error);
            throw error;
        }
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