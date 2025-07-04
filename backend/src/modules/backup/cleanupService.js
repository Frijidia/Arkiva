import pool from '../../config/database.js';
import awsStorageService from '../../services/awsStorageService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';

/**
 * Service de nettoyage automatique des sauvegardes
 * Supprime les sauvegardes de plus de 14 jours
 */
class CleanupService {
  constructor() {
    this.RETENTION_DAYS = 14; // 14 jours de rétention
  }

  /**
   * Nettoie les anciennes sauvegardes automatiques
   */
  async cleanupOldBackups() {
    console.log(`🧹 [Cleanup] Début du nettoyage des sauvegardes de plus de ${this.RETENTION_DAYS} jours`);
    
    try {
      // Calculer la date limite
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.RETENTION_DAYS);
      
      // Récupérer les anciennes sauvegardes automatiques
      const result = await pool.query(`
        SELECT * FROM sauvegardes 
        WHERE mode = 'automatic' 
        AND created_at < $1
        ORDER BY created_at ASC
      `, [cutoffDate]);

      if (result.rows.length === 0) {
        console.log(`🧹 [Cleanup] Aucune sauvegarde ancienne à supprimer`);
        return { deleted: 0, errors: 0 };
      }

      console.log(`🧹 [Cleanup] ${result.rows.length} sauvegardes anciennes trouvées`);

      let deletedCount = 0;
      let errorCount = 0;

      for (const backup of result.rows) {
        try {
          await this.deleteBackup(backup);
          deletedCount++;
          console.log(`✅ [Cleanup] Sauvegarde ${backup.sauvegarde_id} supprimée`);
        } catch (error) {
          errorCount++;
          console.error(`❌ [Cleanup] Erreur lors de la suppression de la sauvegarde ${backup.sauvegarde_id}:`, error);
        }
      }

      // Log de l'action de nettoyage
      await logAction(
        'system',
        ACTIONS.DELETE,
        TARGET_TYPES.SYSTEM,
        'cleanup',
        {
          message: `Nettoyage automatique: ${deletedCount} sauvegardes supprimées, ${errorCount} erreurs`,
          deleted_count: deletedCount,
          error_count: errorCount,
          retention_days: this.RETENTION_DAYS
        }
      );

      console.log(`🧹 [Cleanup] Nettoyage terminé: ${deletedCount} supprimées, ${errorCount} erreurs`);
      return { deleted: deletedCount, errors: errorCount };

    } catch (error) {
      console.error(`❌ [Cleanup] Erreur lors du nettoyage:`, error);
      throw error;
    }
  }

  /**
   * Supprime une sauvegarde spécifique (fichier S3 + enregistrement DB)
   */
  async deleteBackup(backup) {
    try {
      // Supprimer le fichier S3 s'il existe
      if (backup.s3_key) {
        await awsStorageService.deleteFile(backup.s3_key);
        console.log(`🗑️ [Cleanup] Fichier S3 supprimé: ${backup.s3_key}`);
      }

      // Supprimer l'enregistrement de la base
      await pool.query('DELETE FROM sauvegardes WHERE sauvegarde_id = $1', [backup.sauvegarde_id]);
      console.log(`🗑️ [Cleanup] Enregistrement DB supprimé: ${backup.sauvegarde_id}`);

    } catch (error) {
      console.error(`❌ [Cleanup] Erreur lors de la suppression de la sauvegarde ${backup.sauvegarde_id}:`, error);
      throw error;
    }
  }

  /**
   * Nettoie les anciennes versions (optionnel, pour les versions automatiques)
   */
  async cleanupOldVersions() {
    console.log(`🧹 [Cleanup] Début du nettoyage des versions de plus de ${this.RETENTION_DAYS} jours`);
    
    try {
      // Calculer la date limite
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.RETENTION_DAYS);
      
      // Récupérer les anciennes versions automatiques
      const result = await pool.query(`
        SELECT * FROM versions 
        WHERE version_number = 'auto' 
        AND created_at < $1
        ORDER BY created_at ASC
      `, [cutoffDate]);

      if (result.rows.length === 0) {
        console.log(`🧹 [Cleanup] Aucune version ancienne à supprimer`);
        return { deleted: 0, errors: 0 };
      }

      console.log(`🧹 [Cleanup] ${result.rows.length} versions anciennes trouvées`);

      let deletedCount = 0;
      let errorCount = 0;

      for (const version of result.rows) {
        try {
          await this.deleteVersion(version);
          deletedCount++;
          console.log(`✅ [Cleanup] Version ${version.version_id} supprimée`);
        } catch (error) {
          errorCount++;
          console.error(`❌ [Cleanup] Erreur lors de la suppression de la version ${version.version_id}:`, error);
        }
      }

      console.log(`🧹 [Cleanup] Nettoyage des versions terminé: ${deletedCount} supprimées, ${errorCount} erreurs`);
      return { deleted: deletedCount, errors: errorCount };

    } catch (error) {
      console.error(`❌ [Cleanup] Erreur lors du nettoyage des versions:`, error);
      throw error;
    }
  }

  /**
   * Supprime une version spécifique
   */
  async deleteVersion(version) {
    try {
      // Supprimer le fichier S3 s'il existe
      if (version.s3_key) {
        await awsStorageService.deleteFile(version.s3_key);
        console.log(`🗑️ [Cleanup] Fichier S3 supprimé: ${version.s3_key}`);
      }

      // Supprimer l'enregistrement de la base
      await pool.query('DELETE FROM versions WHERE version_id = $1', [version.version_id]);
      console.log(`🗑️ [Cleanup] Enregistrement DB supprimé: ${version.version_id}`);

    } catch (error) {
      console.error(`❌ [Cleanup] Erreur lors de la suppression de la version ${version.version_id}:`, error);
      throw error;
    }
  }

  /**
   * Exécute le nettoyage complet (sauvegardes + versions)
   */
  async runFullCleanup() {
    console.log(`🧹 [Cleanup] Début du nettoyage complet`);
    
    try {
      const backupResult = await this.cleanupOldBackups();
      const versionResult = await this.cleanupOldVersions();

      const totalDeleted = backupResult.deleted + versionResult.deleted;
      const totalErrors = backupResult.errors + versionResult.errors;

      console.log(`🧹 [Cleanup] Nettoyage complet terminé: ${totalDeleted} éléments supprimés, ${totalErrors} erreurs`);
      
      return {
        backups: backupResult,
        versions: versionResult,
        total: { deleted: totalDeleted, errors: totalErrors }
      };

    } catch (error) {
      console.error(`❌ [Cleanup] Erreur lors du nettoyage complet:`, error);
      throw error;
    }
  }
}

export default new CleanupService(); 