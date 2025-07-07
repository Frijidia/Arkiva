import cron from 'node-cron';
import cleanupService from './cleanupService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';

// Cron de nettoyage automatique
// Exécute le nettoyage tous les jours à 2h du matin
class CleanupCron {
  constructor() {
    this.isRunning = false;
    this.lastRun = null;
    this.schedule = '0 2 * * *'; // Tous les jours à 2h du matin
  }

  // Démarrer le cron de nettoyage
  start() {
    console.log('🕐 [CleanupCron] Démarrage du cron de nettoyage automatique...');
    console.log(`📅 [CleanupCron] Planification: ${this.schedule} (tous les jours à 2h)`);

    cron.schedule(this.schedule, async () => {
      await this.performCleanup();
    }, {
      scheduled: true,
      timezone: "Europe/Paris"
    });

    console.log('✅ [CleanupCron] Cron de nettoyage démarré avec succès');
  }

  // Arrêter le cron de nettoyage
  stop() {
    console.log('🛑 [CleanupCron] Arrêt du cron de nettoyage...');
    cron.getTasks().forEach(task => task.stop());
    console.log('✅ [CleanupCron] Cron de nettoyage arrêté');
  }

  // Exécuter le nettoyage manuellement
  async performCleanup() {
    if (this.isRunning) {
      console.log('⚠️ [CleanupCron] Nettoyage déjà en cours, ignoré');
      return;
    }

    this.isRunning = true;
    const startTime = new Date();

    try {
      console.log('🚀 [CleanupCron] Début du nettoyage automatique...');
      
      // Exécuter le nettoyage complet
      const result = await cleanupService.performFullCleanup();
      
      this.lastRun = new Date();
      const duration = new Date() - startTime;

      // Log de l'action de nettoyage automatique
      await logAction(
        null, // system action
        ACTIONS.SYSTEM,
        TARGET_TYPES.SYSTEM,
        'cleanup_cron',
        {
          message: `Nettoyage automatique terminé: ${result.total.deleted} éléments supprimés, ${result.total.errors} erreurs`,
          result,
          duration_ms: duration,
          auto_cleanup: true,
          cron_execution: true
        }
      );

      console.log(`✅ [CleanupCron] Nettoyage automatique terminé en ${duration}ms`);
      console.log(`📊 [CleanupCron] Résultats:`);
      console.log(`   - Sauvegardes supprimées: ${result.backups.deletedCount}`);
      console.log(`   - Versions supprimées: ${result.versions.deletedCount}`);
      console.log(`   - Total supprimé: ${result.total.deleted}`);
      console.log(`   - Erreurs: ${result.total.errors}`);

    } catch (error) {
      console.error('❌ [CleanupCron] Erreur lors du nettoyage automatique:', error);
      
      // Log de l'erreur
      await logAction(
        null, // system action
        ACTIONS.SYSTEM,
        TARGET_TYPES.SYSTEM,
        'cleanup_cron_error',
        {
          message: `Erreur lors du nettoyage automatique: ${error.message}`,
          error: error.message,
          stack: error.stack,
          auto_cleanup: true,
          cron_execution: true
        }
      );
    } finally {
      this.isRunning = false;
    }
  }

  // Obtenir le statut du cron
  getStatus() {
    return {
      isRunning: this.isRunning,
      lastRun: this.lastRun,
      schedule: this.schedule,
      nextRun: this.getNextRun()
    };
  }

  // Calculer la prochaine exécution
  getNextRun() {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(2, 0, 0, 0);
    return tomorrow;
  }

  // Forcer l'exécution immédiate (pour les tests)
  async forceRun() {
    console.log('🔧 [CleanupCron] Exécution forcée du nettoyage...');
    await this.performCleanup();
  }
}

export default new CleanupCron(); 