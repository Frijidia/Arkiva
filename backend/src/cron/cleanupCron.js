import cron from 'node-cron';
import cleanupService from '../modules/backup/cleanupService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../modules/audit/auditService.js';

/**
 * Script de nettoyage automatique quotidien
 * Exécuté tous les jours à 2h du matin
 */
class CleanupCron {
  constructor() {
    this.isRunning = false;
  }

  /**
   * Démarre le cron de nettoyage
   */
  start() {
    console.log('🕐 [Cron] Démarrage du cron de nettoyage automatique');
    
    // Exécuter tous les jours à 2h du matin
    cron.schedule('0 2 * * *', async () => {
      await this.runCleanup();
    }, {
      scheduled: true,
      timezone: "Europe/Paris"
    });

    console.log('✅ [Cron] Cron de nettoyage programmé pour 2h du matin tous les jours');
  }

  /**
   * Exécute le nettoyage
   */
  async runCleanup() {
    if (this.isRunning) {
      console.log('⚠️ [Cron] Nettoyage déjà en cours, ignoré');
      return;
    }

    this.isRunning = true;
    console.log('🧹 [Cron] Début du nettoyage automatique quotidien');

    try {
      const result = await cleanupService.runFullCleanup();
      
      // Log de l'action de nettoyage automatique
      await logAction(
        'system',
        ACTIONS.DELETE,
        TARGET_TYPES.SYSTEM,
        'cron_cleanup',
        {
          message: `Nettoyage automatique quotidien terminé: ${result.total.deleted} éléments supprimés, ${result.total.errors} erreurs`,
          result: result,
          type: 'daily_cleanup'
        }
      );

      console.log('✅ [Cron] Nettoyage automatique terminé avec succès');
      console.log(`📊 [Cron] Résultats: ${result.total.deleted} supprimés, ${result.total.errors} erreurs`);

    } catch (error) {
      console.error('❌ [Cron] Erreur lors du nettoyage automatique:', error);
      
      // Log de l'erreur
      await logAction(
        'system',
        ACTIONS.ERROR,
        TARGET_TYPES.SYSTEM,
        'cron_cleanup_error',
        {
          message: `Erreur lors du nettoyage automatique: ${error.message}`,
          error: error.message,
          type: 'daily_cleanup_error'
        }
      );
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Arrête le cron
   */
  stop() {
    console.log('🛑 [Cron] Arrêt du cron de nettoyage');
    // Le cron s'arrête automatiquement quand le processus se termine
  }
}

export default new CleanupCron(); 