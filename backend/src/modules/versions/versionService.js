import { logAction } from '../audit/auditService.js';
import { v4 as uuidv4 } from 'uuid';
import versionModel from './versionModel.js';
import awsStorageService from '../../services/awsStorageService.js';

class VersionService {
    async createNewVersion(cibleId, type, content, versionMetadata, utilisateur_id) {
        try {
            const versionId = uuidv4();

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

            // Upload vers S3
            const s3Result = await awsStorageService.uploadVersion(contentBuffer, versionId, cibleId, type);

            // Insérer la nouvelle version dans la base de données
            const newVersion = await versionModel.createVersion({
                id: versionId,
                cible_id: cibleId,
                type: type,
                version_number: versionMetadata.version_number,
                storage_path: s3Result.key, // Clé S3 au lieu du chemin local
                metadata: {
                    ...versionMetadata,
                    s3Location: s3Result.location,
                    s3Size: s3Result.size
                },
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
                        s3_location: s3Result.location,
                        date: new Date()
                    }
                );
            }

            return newVersion;

        } catch (error) {
            console.error('Erreur lors de la création de la version:', error);
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
            // Télécharger le contenu depuis S3
            const content = await awsStorageService.downloadVersion(version.storage_path);
            
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
            // Supprimer le fichier de S3
            await awsStorageService.deleteVersion(version.storage_path);

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

        if (!version1 || !version2) {
            throw new Error('Une ou plusieurs versions non trouvées');
        }

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

    // Générer une URL signée pour télécharger une version
    async getVersionDownloadUrl(versionId, expiresIn = 3600) {
        const version = await versionModel.getVersionById(versionId);
        if (!version) {
            return null;
        }

        try {
            return await awsStorageService.getSignedDownloadUrl(version.storage_path, expiresIn);
        } catch (error) {
            console.error('Erreur lors de la génération de l\'URL de téléchargement:', error);
            throw error;
        }
    }
}

export default new VersionService(); 