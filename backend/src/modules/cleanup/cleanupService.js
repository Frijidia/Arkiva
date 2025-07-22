import pool from '../../config/database.js';
import { S3Client, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';

const s3 = new S3Client({
  region: 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const s3BaseUrl = `https://${process.env.AWS_S3_BUCKET_NAME}.s3.amazonaws.com/`;

/**
 * Service de nettoyage automatique des sauvegardes et versions inutilisées
 * Supprime les éléments après 10 jours d'inactivité
 */
class CleanupService {
  
  
  // Nettoyer les sauvegardes inutilisées après 10 jours
  
  async cleanupUnusedBackups() {
    try {
      console.log('[Cleanup] Début du nettoyage des sauvegardes inutilisées...');
      
      // Récupérer les sauvegardes créées il y a plus de 10 jours
      const tenDaysAgo = new Date();
      tenDaysAgo.setDate(tenDaysAgo.getDate() - 10);
      
      const result = await pool.query(`
        SELECT backup_id, type, cible_id, chemin_s3, created_at, entreprise_id
        FROM backups 
        WHERE created_at < $1 
        AND is_deleted = false
        AND NOT EXISTS (
          SELECT 1 FROM restores 
          WHERE restore_source_type = 'backup' 
          AND restore_source_id = backups.backup_id
        )
      `, [tenDaysAgo]);
      
      console.log(`[Cleanup] ${result.rows.length} sauvegardes inutilisées trouvées`);
      
      let deletedCount = 0;
      let errorCount = 0;
      
      for (const backup of result.rows) {
        try {
          // Supprimer le fichier S3
          if (backup.chemin_s3) {
            const key = backup.chemin_s3.replace(s3BaseUrl, '');
            await s3.send(new DeleteObjectCommand({
              Bucket: process.env.AWS_S3_BUCKET_NAME,
              Key: key,
            }));
            console.log(`[Cleanup] Fichier S3 supprimé: ${key}`);
          }
          
          // Marquer comme supprimé en base
          await pool.query(
            'UPDATE backups SET is_deleted = true, deleted_at = NOW() WHERE backup_id = $1',
            [backup.backup_id]
          );
          
          // Log de l'action
          await logAction(
            null, // system action
            ACTIONS.DELETE,
            TARGET_TYPES.BACKUP,
            backup.backup_id,
            {
              message: `Nettoyage automatique: Sauvegarde ${backup.type} supprimée après 10 jours d'inactivité`,
              backup_id: backup.backup_id,
              type: backup.type,
              cible_id: backup.cible_id,
              auto_cleanup: true,
              days_inactive: 10
            }
          );
          
          deletedCount++;
          console.log(`[Cleanup] Sauvegarde ${backup.backup_id} supprimée`);
          
        } catch (error) {
          console.error(`[Cleanup] Erreur lors de la suppression de la sauvegarde ${backup.backup_id}:`, error);
          errorCount++;
        }
      }
      
      console.log(`[Cleanup] Nettoyage terminé: ${deletedCount} supprimées, ${errorCount} erreurs`);
      return { deletedCount, errorCount };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors du nettoyage des sauvegardes:', error);
      throw error;
    }
  }
  
  // Nettoyer les versions inutilisées après 10 jours
  async cleanupUnusedVersions() {
    try {
      console.log('[Cleanup] Début du nettoyage des versions inutilisées...');
      
      // Récupérer les versions créées il y a plus de 10 jours
      const tenDaysAgo = new Date();
      tenDaysAgo.setDate(tenDaysAgo.getDate() - 10);
      
      const result = await pool.query(`
        SELECT version_id, type, cible_id, chemin_s3, created_at, entreprise_id
        FROM versions 
        WHERE created_at < $1 
        AND is_deleted = false
        AND NOT EXISTS (
          SELECT 1 FROM restores 
          WHERE restore_source_type = 'version' 
          AND restore_source_id = versions.version_id
        )
      `, [tenDaysAgo]);
      
      console.log(`[Cleanup] ${result.rows.length} versions inutilisées trouvées`);
      
      let deletedCount = 0;
      let errorCount = 0;
      
      for (const version of result.rows) {
        try {
          // Supprimer le fichier S3
          if (version.chemin_s3) {
            const key = version.chemin_s3.replace(s3BaseUrl, '');
            await s3.send(new DeleteObjectCommand({
              Bucket: process.env.AWS_S3_BUCKET_NAME,
              Key: key,
            }));
            console.log(`[Cleanup] Fichier S3 supprimé: ${key}`);
          }
          
          // Marquer comme supprimé en base
          await pool.query(
            'UPDATE versions SET is_deleted = true, deleted_at = NOW() WHERE version_id = $1',
            [version.version_id]
          );
          
          // Log de l'action
          await logAction(
            null, // system action
            ACTIONS.DELETE,
            TARGET_TYPES.VERSION,
            version.version_id,
            {
              message: `Nettoyage automatique: Version ${version.type} supprimée après 10 jours d'inactivité`,
              version_id: version.version_id,
              type: version.type,
              cible_id: version.cible_id,
              auto_cleanup: true,
              days_inactive: 10
            }
          );
          
          deletedCount++;
          console.log(`[Cleanup] Version ${version.version_id} supprimée`);
          
        } catch (error) {
          console.error(`[Cleanup] Erreur lors de la suppression de la version ${version.version_id}:`, error);
          errorCount++;
        }
      }
      
      console.log(`[Cleanup] Nettoyage terminé: ${deletedCount} supprimées, ${errorCount} erreurs`);
      return { deletedCount, errorCount };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors du nettoyage des versions:', error);
      throw error;
    }
  }
  
  // Nettoyage complet (sauvegardes + versions)
  async performFullCleanup() {
    try {
      console.log('[Cleanup] Début du nettoyage complet...');
      
      const backupResult = await this.cleanupUnusedBackups();
      const versionResult = await this.cleanupUnusedVersions();
      
      const totalDeleted = backupResult.deletedCount + versionResult.deletedCount;
      const totalErrors = backupResult.errorCount + versionResult.errorCount;
      
      console.log(`[Cleanup] Nettoyage complet terminé:`);
      console.log(`   - Sauvegardes supprimées: ${backupResult.deletedCount}`);
      console.log(`   - Versions supprimées: ${versionResult.deletedCount}`);
      console.log(`   - Total supprimé: ${totalDeleted}`);
      console.log(`   - Erreurs: ${totalErrors}`);
      
      return {
        backups: backupResult,
        versions: versionResult,
        total: { deleted: totalDeleted, errors: totalErrors }
      };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors du nettoyage complet:', error);
      throw error;
    }
  }
  
  // Obtenir les statistiques de nettoyage
  async getCleanupStats() {
    try {
      const tenDaysAgo = new Date();
      tenDaysAgo.setDate(tenDaysAgo.getDate() - 10);
      
      // Statistiques des sauvegardes
      const backupStats = await pool.query(`
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN created_at < $1 THEN 1 END) as old_unused,
          COUNT(CASE WHEN is_deleted = true THEN 1 END) as deleted
        FROM backups
        WHERE NOT EXISTS (
          SELECT 1 FROM restores 
          WHERE restore_source_type = 'backup' 
          AND restore_source_id = backups.backup_id
        )
      `, [tenDaysAgo]);
      
      // Statistiques des versions
      const versionStats = await pool.query(`
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN created_at < $1 THEN 1 END) as old_unused,
          COUNT(CASE WHEN is_deleted = true THEN 1 END) as deleted
        FROM versions
        WHERE NOT EXISTS (
          SELECT 1 FROM restores 
          WHERE restore_source_type = 'version' 
          AND restore_source_id = versions.version_id
        )
      `, [tenDaysAgo]);
      
      return {
        backups: backupStats.rows[0],
        versions: versionStats.rows[0],
        cleanup_threshold_days: 10
      };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors de la récupération des stats:', error);
      throw error;
    }
  }

  // Supprimer manuellement une sauvegarde spécifique
  async deleteSpecificBackup(backup_id, user_id) {
    try {
      console.log(`[Cleanup] Suppression manuelle de la sauvegarde ${backup_id}`);
      
      // Récupérer les infos de la sauvegarde
      const backupResult = await pool.query(
        'SELECT * FROM backups WHERE backup_id = $1 AND is_deleted = false',
        [backup_id]
      );
      
      if (backupResult.rowCount === 0) {
        throw new Error('Sauvegarde non trouvée ou déjà supprimée');
      }
      
      const backup = backupResult.rows[0];
      
      // Supprimer le fichier S3
      if (backup.chemin_s3) {
        const key = backup.chemin_s3.replace(s3BaseUrl, '');
        await s3.send(new DeleteObjectCommand({
          Bucket: process.env.AWS_S3_BUCKET_NAME,
          Key: key,
        }));
        console.log(`[Cleanup] Fichier S3 supprimé: ${key}`);
      }
      
      // Marquer comme supprimé en base
      await pool.query(
        'UPDATE backups SET is_deleted = true, deleted_at = NOW() WHERE backup_id = $1',
        [backup_id]
      );
      
      console.log(`[Cleanup] Sauvegarde ${backup_id} supprimée manuellement`);
      
      return {
        backup_id,
        type: backup.type,
        cible_id: backup.cible_id,
        deleted_at: new Date(),
        manual_deletion: true,
        user_id
      };
      
    } catch (error) {
      console.error(`[Cleanup] Erreur lors de la suppression manuelle de la sauvegarde ${backup_id}:`, error);
      throw error;
    }
  }

  // Supprimer manuellement une version spécifique
  async deleteSpecificVersion(version_id, user_id) {
    try {
      console.log(`[Cleanup] Suppression manuelle de la version ${version_id}`);
      
      // Récupérer les infos de la version
      const versionResult = await pool.query(
        'SELECT * FROM versions WHERE version_id = $1 AND is_deleted = false',
        [version_id]
      );
      
      if (versionResult.rowCount === 0) {
        throw new Error('Version non trouvée ou déjà supprimée');
      }
      
      const version = versionResult.rows[0];
      
      // Supprimer le fichier S3
      if (version.chemin_s3) {
        const key = version.chemin_s3.replace(s3BaseUrl, '');
        await s3.send(new DeleteObjectCommand({
          Bucket: process.env.AWS_S3_BUCKET_NAME,
          Key: key,
        }));
        console.log(`[Cleanup] Fichier S3 supprimé: ${key}`);
      }
      
      // Marquer comme supprimé en base
      await pool.query(
        'UPDATE versions SET is_deleted = true, deleted_at = NOW() WHERE version_id = $1',
        [version_id]
      );
      
      console.log(`[Cleanup] Version ${version_id} supprimée manuellement`);
      
      return {
        version_id,
        type: version.type,
        cible_id: version.cible_id,
        deleted_at: new Date(),
        manual_deletion: true,
        user_id
      };
      
    } catch (error) {
      console.error(`[Cleanup] Erreur lors de la suppression manuelle de la version ${version_id}:`, error);
      throw error;
    }
  }

  // Obtenir la liste des sauvegardes avec pagination
  async getBackupsList({ page = 1, limit = 20, type, entreprise_id }) {
    try {
      const offset = (page - 1) * limit;
      let whereClause = 'WHERE is_deleted = false';
      const params = [];
      let paramIndex = 1;

      if (type) {
        whereClause += ` AND type = $${paramIndex}`;
        params.push(type);
        paramIndex++;
      }

      if (entreprise_id) {
        whereClause += ` AND entreprise_id = $${paramIndex}`;
        params.push(entreprise_id);
        paramIndex++;
      }

      // Compter le total
      const countResult = await pool.query(
        `SELECT COUNT(*) as total FROM backups ${whereClause}`,
        params
      );
      const total = parseInt(countResult.rows[0].total);

      // Récupérer les sauvegardes
      const backupsResult = await pool.query(
        `SELECT * FROM backups ${whereClause} 
         ORDER BY created_at DESC 
         LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
        [...params, limit, offset]
      );

      return {
        backups: backupsResult.rows,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors de la récupération des sauvegardes:', error);
      throw error;
    }
  }

  // Obtenir la liste des versions avec pagination
  async getVersionsList({ page = 1, limit = 20, type, entreprise_id }) {
    try {
      const offset = (page - 1) * limit;
      let whereClause = 'WHERE is_deleted = false';
      const params = [];
      let paramIndex = 1;

      if (type) {
        whereClause += ` AND type = $${paramIndex}`;
        params.push(type);
        paramIndex++;
      }

      if (entreprise_id) {
        whereClause += ` AND entreprise_id = $${paramIndex}`;
        params.push(entreprise_id);
        paramIndex++;
      }

      // Compter le total
      const countResult = await pool.query(
        `SELECT COUNT(*) as total FROM versions ${whereClause}`,
        params
      );
      const total = parseInt(countResult.rows[0].total);

      // Récupérer les versions
      const versionsResult = await pool.query(
        `SELECT * FROM versions ${whereClause} 
         ORDER BY created_at DESC 
         LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
        [...params, limit, offset]
      );

      return {
        versions: versionsResult.rows,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      };
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors de la récupération des versions:', error);
      throw error;
    }
  }

  // Obtenir les détails d'une sauvegarde
  async getBackupDetails(backup_id) {
    try {
      const result = await pool.query(
        'SELECT * FROM backups WHERE backup_id = $1',
        [backup_id]
      );
      
      return result.rows[0] || null;
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors de la récupération des détails de la sauvegarde:', error);
      throw error;
    }
  }

  // Obtenir les détails d'une version
  async getVersionDetails(version_id) {
    try {
      const result = await pool.query(
        'SELECT * FROM versions WHERE version_id = $1',
        [version_id]
      );
      
      return result.rows[0] || null;
      
    } catch (error) {
      console.error('[Cleanup] Erreur lors de la récupération des détails de la version:', error);
      throw error;
    }
  }
}

export default new CleanupService(); 