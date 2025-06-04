import fs from 'fs';
import path from 'path';
import unzipper from 'unzipper';
import fileService from '../fichiers/fichierService.js';
import folderService from '../dosiers/folderService.js';
import systemService from '../system/systemService.js';
import versionService from './versionService.js';
import auditService from '../audit/auditService.js';
import userService from '../users/userService.js';

class RestoreService {
    constructor() {
        this.fileEntries = {};
        this.metadata = null;
    }

    async restoreBackup(backupId, utilisateur_id) {
        try {
            const backup = await this.getBackupDetails(backupId);
            if (!backup) {
                throw new Error('Sauvegarde non trouvée.');
            }

            const archivePath = backup.chemin_sauvegarde;
            if (!fs.existsSync(archivePath)) {
                throw new Error('Fichier d\'archive de sauvegarde introuvable.');
            }

            await this.extractArchive(archivePath);
            if (!this.metadata) {
                throw new Error('Métadonnées de sauvegarde introuvables dans l\'archive.');
            }

            switch (backup.type) {
                case 'fichier':
                    await this.restoreFile(backup, utilisateur_id);
                    break;
                case 'dossier':
                    await this.restoreFolder(backup, utilisateur_id);
                    break;
                case 'système':
                    await this.restoreSystem(backup, utilisateur_id);
                    break;
                default:
                    throw new Error(`Type de sauvegarde non supporté: ${backup.type}`);
            }

            await this.logRestoreAction(backup, utilisateur_id);
            return { message: `Restauration de la sauvegarde ID ${backupId} terminée avec succès.` };

        } catch (error) {
            console.error(`Erreur dans restoreService.restoreBackup pour sauvegarde ID ${backupId}:`, error);
            throw error;
        }
    }

    async extractArchive(archivePath) {
        return new Promise((resolve, reject) => {
            const stream = fs.createReadStream(archivePath).pipe(unzipper.Parse({ forceEntryData: true }));

            stream.on('entry', async (entry) => {
                if (entry.type === 'File') {
                    if (entry.path.startsWith('metadata_') || entry.path === 'system_metadata.json') {
                        try {
                            const content = await entry.buffer();
                            this.metadata = JSON.parse(content.toString());
                        } catch (parseError) {
                            console.error(`Erreur lors de la lecture des métadonnées:`, parseError);
                        }
                    } else {
                        this.fileEntries[entry.path] = entry;
                    }
                }
                entry.autodrain();
            });

            stream.on('close', resolve);
            stream.on('error', reject);
        });
    }

    async restoreFile(backup, utilisateur_id) {
        const fileEntry = this.fileEntries[this.metadata.originalFileName];
        if (!fileEntry) {
            throw new Error(`Contenu du fichier ${this.metadata.originalFileName} introuvable dans l'archive.`);
        }

        const fileContent = await fileEntry.buffer();
        const existingFile = await fileService.getFileDetails(this.metadata.id);

        if (existingFile) {
            await this.createNewVersion(existingFile, fileContent, utilisateur_id);
        } else {
            await this.createNewFile(fileContent, utilisateur_id);
        }
    }

    async restoreFolder(backup, utilisateur_id) {
        const existingFolder = await folderService.getFolderDetails(this.metadata.id);
        
        if (existingFolder) {
            await this.updateExistingFolder(existingFolder, utilisateur_id);
        } else {
            await this.createNewFolder(utilisateur_id);
        }

        await this.restoreFolderContent(this.metadata, utilisateur_id);
    }

    async restoreSystem(backup, utilisateur_id) {
        const systemStatus = await systemService.getSystemStatus();
        if (systemStatus.isActive) {
            throw new Error('Le système est actuellement en cours d\'utilisation. Impossible de restaurer.');
        }

        await this.restoreSystemConfigurations(utilisateur_id);
        await this.restoreSystemParameters(utilisateur_id);
        await this.restoreSystemFolders(utilisateur_id);
        await this.restoreSystemUsers(utilisateur_id);
        await this.updateSystemVersion(utilisateur_id);
    }

    // Méthodes utilitaires pour la restauration
    async createNewVersion(existingFile, fileContent, utilisateur_id) {
        const versionMetadata = {
            ...this.metadata,
            version_number: (existingFile.version_number || 0) + 1,
            parent_version_id: existingFile.id,
            created_by: utilisateur_id,
            created_at: new Date()
        };

        const newVersion = await versionService.createNewVersion(
            this.metadata.id,
            fileContent,
            versionMetadata,
            utilisateur_id
        );

        await versionService.updateFileVersion(
            this.metadata.id,
            newVersion.id,
            utilisateur_id
        );
    }

    async createNewFile(fileContent, utilisateur_id) {
        const fileMetadata = {
            ...this.metadata,
            created_by: utilisateur_id,
            created_at: new Date(),
            version_number: 1
        };

        await fileService.createFileFromBackup(
            this.metadata.id,
            fileContent,
            fileMetadata,
            utilisateur_id
        );
    }

    async updateExistingFolder(existingFolder, utilisateur_id) {
        await folderService.updateFolder(
            this.metadata.id,
            {
                ...this.metadata,
                updated_by: utilisateur_id,
                updated_at: new Date()
            }
        );
    }

    async createNewFolder(utilisateur_id) {
        await folderService.createFolderFromBackup(
            this.metadata.id,
            {
                ...this.metadata,
                created_by: utilisateur_id,
                created_at: new Date()
            },
            utilisateur_id
        );
    }

    async restoreFolderContent(folderMetadata, utilisateur_id) {
        if (folderMetadata.files) {
            await this.restoreFolderFiles(folderMetadata, utilisateur_id);
        }
        if (folderMetadata.subfolders) {
            await this.restoreSubfolders(folderMetadata, utilisateur_id);
        }
    }

    async restoreFolderFiles(folderMetadata, utilisateur_id) {
        for (const fileMetadata of folderMetadata.files) {
            try {
                const fileEntry = this.fileEntries[fileMetadata.originalFileName];
                if (!fileEntry) continue;

                const fileContent = await fileEntry.buffer();
                const existingFile = await fileService.getFileDetails(fileMetadata.id);

                if (existingFile) {
                    await this.createNewVersion(existingFile, fileContent, utilisateur_id);
                } else {
                    await this.createNewFile(fileContent, utilisateur_id);
                }
            } catch (error) {
                console.error(`Erreur lors de la restauration du fichier ${fileMetadata.id}:`, error);
            }
        }
    }

    async restoreSubfolders(folderMetadata, utilisateur_id) {
        for (const subfolderMetadata of folderMetadata.subfolders) {
            try {
                const existingSubfolder = await folderService.getFolderDetails(subfolderMetadata.id);
                
                if (existingSubfolder) {
                    await this.updateExistingFolder(existingSubfolder, utilisateur_id);
                } else {
                    await this.createNewFolder(utilisateur_id);
                }

                await this.restoreFolderContent(subfolderMetadata, utilisateur_id);
            } catch (error) {
                console.error(`Erreur lors de la restauration du sous-dossier ${subfolderMetadata.id}:`, error);
            }
        }
    }

    async restoreSystemConfigurations(utilisateur_id) {
        if (!this.metadata.configurations) return;

        for (const [key, value] of Object.entries(this.metadata.configurations)) {
            try {
                await systemService.updateConfiguration(key, value, utilisateur_id);
            } catch (error) {
                console.error(`Erreur lors de la restauration de la configuration ${key}:`, error);
            }
        }
    }

    async restoreSystemParameters(utilisateur_id) {
        if (!this.metadata.parameters) return;

        for (const [key, value] of Object.entries(this.metadata.parameters)) {
            try {
                await systemService.updateParameter(key, value, utilisateur_id);
            } catch (error) {
                console.error(`Erreur lors de la restauration du paramètre ${key}:`, error);
            }
        }
    }

    async restoreSystemFolders(utilisateur_id) {
        if (!this.metadata.systemFolders) return;

        for (const folderMetadata of this.metadata.systemFolders) {
            try {
                const existingFolder = await folderService.getFolderDetails(folderMetadata.id);
                
                if (existingFolder) {
                    await this.updateExistingFolder(existingFolder, utilisateur_id);
                } else {
                    await this.createNewFolder(utilisateur_id);
                }

                await this.restoreFolderContent(folderMetadata, utilisateur_id);
            } catch (error) {
                console.error(`Erreur lors de la restauration du dossier système ${folderMetadata.id}:`, error);
            }
        }
    }

    async restoreSystemUsers(utilisateur_id) {
        if (!this.metadata.systemUsers) return;

        for (const userMetadata of this.metadata.systemUsers) {
            try {
                const existingUser = await userService.getUserById(userMetadata.id);
                
                if (existingUser) {
                    await userService.updateUser(
                        userMetadata.id,
                        {
                            ...userMetadata,
                            updated_by: utilisateur_id,
                            updated_at: new Date()
                        }
                    );
                } else {
                    await userService.createUserFromBackup(
                        userMetadata.id,
                        {
                            ...userMetadata,
                            created_by: utilisateur_id,
                            created_at: new Date()
                        }
                    );
                }
            } catch (error) {
                console.error(`Erreur lors de la restauration de l'utilisateur système ${userMetadata.id}:`, error);
            }
        }
    }

    async updateSystemVersion(utilisateur_id) {
        if (this.metadata.version) {
            await systemService.updateSystemVersion(this.metadata.version, utilisateur_id);
        }
    }

    async logRestoreAction(backup, utilisateur_id) {
        if (!auditService || !utilisateur_id) return;

        await auditService.logAction({
            utilisateur_id,
            action: 'restauration',
            cible_type: backup.type,
            cible_id: backup.cible_id,
            details: {
                backup_id: backup.id,
                type: backup.type,
                date: new Date()
            },
            date: new Date()
        });
    }
}

export default new RestoreService(); 