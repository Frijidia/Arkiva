import fs from 'fs';
import path from 'path';
import unzipper from 'unzipper';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';
import versionService from './versionService.js';
import * as auditService from '../audit/auditService.js';
//import userService from '../auth/authController.js';

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
                    await this.restoreDossier(backup, utilisateur_id);
                    break;
                case 'casier':
                    await this.restoreCasier(backup, utilisateur_id);
                    break;
                case 'armoire':
                    await this.restoreArmoire(backup, utilisateur_id);
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

    async restoreDossier(backup, utilisateur_id) {
        const existingDossier = await dossierService.getDossierDetails(this.metadata.id);
        
        if (existingDossier) {
            await this.updateExistingDossier(existingDossier, utilisateur_id);
        } else {
            await this.createNewDossier(utilisateur_id);
        }

        await this.restoreDossierContent(this.metadata, utilisateur_id);
    }

    async restoreCasier(backup, utilisateur_id) {
        const existingCasier = await casierService.getCasierDetails(this.metadata.id);
        
        if (existingCasier) {
            await this.updateExistingCasier(existingCasier, utilisateur_id);
        } else {
            await this.createNewCasier(utilisateur_id);
        }

        await this.restoreCasierContent(this.metadata, utilisateur_id);
    }

    async restoreArmoire(backup, utilisateur_id) {
        const existingArmoire = await armoireService.getArmoireDetails(this.metadata.id);
        
        if (existingArmoire) {
            await this.updateExistingArmoire(existingArmoire, utilisateur_id);
        } else {
            await this.createNewArmoire(utilisateur_id);
        }

        await this.restoreArmoireContent(this.metadata, utilisateur_id);
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

    async updateExistingDossier(existingDossier, utilisateur_id) {
        await dossierService.updateDossier(
            this.metadata.id,
            {
                ...this.metadata,
                updated_by: utilisateur_id,
                updated_at: new Date()
            }
        );
    }

    async createNewDossier(utilisateur_id) {
        await dossierService.createDossierFromBackup(
            this.metadata.id,
            {
                ...this.metadata,
                created_by: utilisateur_id,
                created_at: new Date()
            },
            utilisateur_id
        );
    }

    async updateExistingCasier(existingCasier, utilisateur_id) {
        await casierService.updateCasier(
            this.metadata.id,
            {
                ...this.metadata,
                updated_by: utilisateur_id,
                updated_at: new Date()
            }
        );
    }

    async createNewCasier(utilisateur_id) {
        await casierService.createCasierFromBackup(
            this.metadata.id,
            {
                ...this.metadata,
                created_by: utilisateur_id,
                created_at: new Date()
            },
            utilisateur_id
        );
    }

    async updateExistingArmoire(existingArmoire, utilisateur_id) {
        await armoireService.updateArmoire(
            this.metadata.id,
            {
                ...this.metadata,
                updated_by: utilisateur_id,
                updated_at: new Date()
            }
        );
    }

    async createNewArmoire(utilisateur_id) {
        await armoireService.createArmoireFromBackup(
            this.metadata.id,
            {
                ...this.metadata,
                created_by: utilisateur_id,
                created_at: new Date()
            },
            utilisateur_id
        );
    }

    async restoreDossierContent(dossierMetadata, utilisateur_id) {
        if (dossierMetadata.files) {
            await this.restoreDossierFiles(dossierMetadata, utilisateur_id);
        }
        if (dossierMetadata.subdossiers) {
            await this.restoreSubdossiers(dossierMetadata, utilisateur_id);
        }
    }

    async restoreCasierContent(casierMetadata, utilisateur_id) {
        if (casierMetadata.dossiers) {
            await this.restoreCasierDossiers(casierMetadata, utilisateur_id);
        }
    }

    async restoreArmoireContent(armoireMetadata, utilisateur_id) {
        if (armoireMetadata.casiers) {
            await this.restoreArmoireCasiers(armoireMetadata, utilisateur_id);
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