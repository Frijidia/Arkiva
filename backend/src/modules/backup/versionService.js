import db from '../../config/database.js';
import auditService from '../audit/auditService.js'; // Pour la journalisation
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
// Assume a storage directory for versioned files
const VERSIONS_STORAGE_DIR = path.join(__dirname, '../../../../uploads/versions'); // Ajustez ce chemin si nécessaire

// Ensure the storage directory exists
if (!fs.existsSync(VERSIONS_STORAGE_DIR)) {
    fs.mkdirSync(VERSIONS_STORAGE_DIR, { recursive: true });
}

class VersionService {
    constructor() {
        this.initializeDatabase();
    }

    async initializeDatabase() {
        const createVersionsTableSQL = `
            CREATE TABLE IF NOT EXISTS versions (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                file_id UUID NOT NULL REFERENCES fichiers(id),
                version_number INTEGER NOT NULL,
                storage_path TEXT NOT NULL,
                metadata JSONB,
                created_by UUID REFERENCES utilisateurs(id),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(file_id, version_number)
            );

            CREATE INDEX IF NOT EXISTS idx_versions_file_id ON versions(file_id);
            CREATE INDEX IF NOT EXISTS idx_versions_version_number ON versions(version_number);
        `;

        try {
            await db.query(createVersionsTableSQL);
            console.log('Table versions et index créés/mis à jour avec succès');
        } catch (error) {
            console.error('Erreur lors de la création/mise à jour de la table versions:', error);
            throw error;
        }
    }

    // Cette fonction sera responsable de la création d'une nouvelle version d'un fichier existant.
    // Elle gère l'insertion dans la table des versions et le stockage physique du contenu.
    async createNewVersion(fileId, fileContent, versionMetadata, utilisateur_id) {
        console.log(`[versionService] Création d'une nouvelle version pour fichier ${fileId}`);
        
        try {
            // Générer l'UUID avant de créer le fichier
            const versionId = uuidv4();
            const fileVersionDir = path.join(VERSIONS_STORAGE_DIR, fileId);
            const versionContentPath = path.join(fileVersionDir, `${versionId}_content`);

            // Assurer que le répertoire existe
            if (!fs.existsSync(fileVersionDir)) {
                fs.mkdirSync(fileVersionDir, { recursive: true });
            }

            // Stocker le contenu du fichier
            await fs.promises.writeFile(versionContentPath, fileContent);

            // Insérer la nouvelle version dans la base de données
            const result = await db.query(
                'INSERT INTO versions (id, file_id, version_number, storage_path, metadata, created_by) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
                [versionId, fileId, versionMetadata.version_number, versionContentPath, versionMetadata, utilisateur_id]
            );

            const newVersion = result.rows[0];
            console.log(`[versionService] Nouvelle version créée pour fichier ${fileId} avec ID ${versionId}`);

            // Journaliser l'action
            if (auditService && utilisateur_id) {
                await auditService.logAction({
                    utilisateur_id,
                    action: 'creation_version_fichier',
                    cible_type: 'version',
                    cible_id: versionId,
                    details: {
                        file_id: fileId,
                        version_number: newVersion.version_number,
                        storage_path: versionContentPath,
                    },
                    date: new Date()
                });
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
            const result = await db.query(
                'UPDATE fichiers SET current_version_id = $1, updated_by = $2, updated_at = NOW() WHERE id = $3 RETURNING *',
                [newVersionId, utilisateur_id, fileId]
            );

            if (result.rowCount === 0) {
                throw new Error(`Fichier parent ${fileId} non trouvé pour mise à jour de version.`);
            }

            console.log(`[versionService] Version active du fichier ${fileId} mise à jour vers ${newVersionId}`);
            
            // Journaliser l'action
            if (auditService && utilisateur_id) {
                await auditService.logAction({
                    utilisateur_id,
                    action: 'mise_a_jour_version_fichier_parent',
                    cible_type: 'fichier',
                    cible_id: fileId,
                    details: {
                        new_version_id: newVersionId,
                    },
                    date: new Date()
                });
            }

            return result.rows[0];

        } catch (error) {
            console.error(`[versionService] Erreur lors de la mise à jour de la version pour fichier ${fileId}:`, error);
            throw error;
        }
    }

    async getVersionHistory(fileId) {
        try {
            const result = await db.query(
                'SELECT * FROM versions WHERE file_id = $1 ORDER BY version_number DESC',
                [fileId]
            );
            return result.rows;
        } catch (error) {
            console.error(`[versionService] Erreur lors de la récupération de l'historique des versions pour fichier ${fileId}:`, error);
            throw error;
        }
    }

    async getVersionContent(versionId) {
        try {
            const result = await db.query(
                'SELECT * FROM versions WHERE id = $1',
                [versionId]
            );

            if (result.rowCount === 0) {
                throw new Error(`Version ${versionId} non trouvée.`);
            }

            const version = result.rows[0];
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
            const result = await db.query(
                'DELETE FROM versions WHERE id = $1 RETURNING *',
                [versionId]
            );

            if (result.rowCount === 0) {
                throw new Error(`Version ${versionId} non trouvée.`);
            }

            // Supprimer le fichier physique
            if (fs.existsSync(version.storage_path)) {
                await fs.promises.unlink(version.storage_path);
            }

            // Journaliser l'action
            if (auditService && utilisateur_id) {
                await auditService.logAction({
                    utilisateur_id,
                    action: 'suppression_version',
                    cible_type: 'version',
                    cible_id: versionId,
                    details: {
                        file_id: version.file_id,
                        version_number: version.version_number,
                    },
                    date: new Date()
                });
            }

            return result.rows[0];
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
                contentDiff,
                version1: {
                    id: version1.id,
                    version_number: version1.version_number,
                    created_at: version1.created_at
                },
                version2: {
                    id: version2.id,
                    version_number: version2.version_number,
                    created_at: version2.created_at
                }
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
}

export default new VersionService(); 