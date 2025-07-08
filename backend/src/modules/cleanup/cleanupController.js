import cleanupService from './cleanupService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';


// Contrôleur pour le module de nettoyage
 
class CleanupController {

  // Obtenir les statistiques de nettoyage
  async getCleanupStats(req, res) {
    try {
      const stats = await cleanupService.getCleanupStats();
      res.status(200).json({
        message: 'Statistiques de nettoyage récupérées',
        stats
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des stats de nettoyage:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Nettoyer les sauvegardes inutilisées
  async cleanupUnusedBackups(req, res) {
    try {
      const result = await cleanupService.cleanupUnusedBackups();
      res.status(200).json({
        message: 'Nettoyage des sauvegardes terminé',
        result
      });
    } catch (error) {
      console.error('Erreur lors du nettoyage des sauvegardes:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Nettoyer les versions inutilisées
  async cleanupUnusedVersions(req, res) {
    try {
      const result = await cleanupService.cleanupUnusedVersions();
      res.status(200).json({
        message: 'Nettoyage des versions terminé',
        result
      });
    } catch (error) {
      console.error('Erreur lors du nettoyage des versions:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Nettoyage complet (sauvegardes + versions)
  async performFullCleanup(req, res) {
    try {
      const result = await cleanupService.performFullCleanup();
      res.status(200).json({
        message: 'Nettoyage complet terminé',
        result
      });
    } catch (error) {
      console.error('Erreur lors du nettoyage complet:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Supprimer manuellement une sauvegarde spécifique
  async deleteBackup(req, res) {
    try {
      const { backup_id } = req.params;
      const user = req.user;

      if (!backup_id) {
        return res.status(400).json({ error: 'ID de sauvegarde requis' });
      }

      const result = await cleanupService.deleteSpecificBackup(backup_id, user.user_id);
      
      // Log de l'action
      await logAction(
        user.user_id,
        ACTIONS.DELETE,
        TARGET_TYPES.BACKUP,
        backup_id,
        {
          message: `Sauvegarde ${backup_id} supprimée manuellement par ${user.username}`,
          backup_id,
          manual_deletion: true,
          user_id: user.user_id
        }
      );

      res.status(200).json({
        message: 'Sauvegarde supprimée avec succès',
        result
      });
    } catch (error) {
      console.error('Erreur lors de la suppression de la sauvegarde:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Supprimer manuellement une version spécifique
  async deleteVersion(req, res) {
    try {
      const { version_id } = req.params;
      const user = req.user;

      if (!version_id) {
        return res.status(400).json({ error: 'ID de version requis' });
      }

      const result = await cleanupService.deleteSpecificVersion(version_id, user.user_id);
      
      // Log de l'action
      await logAction(
        user.user_id,
        ACTIONS.DELETE,
        TARGET_TYPES.VERSION,
        version_id,
        {
          message: `Version ${version_id} supprimée manuellement par ${user.username}`,
          version_id,
          manual_deletion: true,
          user_id: user.user_id
        }
      );

      res.status(200).json({
        message: 'Version supprimée avec succès',
        result
      });
    } catch (error) {
      console.error('Erreur lors de la suppression de la version:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Obtenir la liste des sauvegardes disponibles
  async getBackupsList(req, res) {
    try {
      const { page = 1, limit = 20, type, entreprise_id } = req.query;
      const result = await cleanupService.getBackupsList({
        page: parseInt(page),
        limit: parseInt(limit),
        type,
        entreprise_id
      });

      res.status(200).json({
        message: 'Liste des sauvegardes récupérée',
        backups: result.backups,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des sauvegardes:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Obtenir la liste des versions disponibles
  async getVersionsList(req, res) {
    try {
      const { page = 1, limit = 20, type, entreprise_id } = req.query;
      const result = await cleanupService.getVersionsList({
        page: parseInt(page),
        limit: parseInt(limit),
        type,
        entreprise_id
      });

      res.status(200).json({
        message: 'Liste des versions récupérée',
        versions: result.versions,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des versions:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

  // Obtenir les détails d'une sauvegarde
  async getBackupDetails(req, res) {
    try {
      const { backup_id } = req.params;
      
      if (!backup_id) {
        return res.status(400).json({ error: 'ID de sauvegarde requis' });
      }

      const backup = await cleanupService.getBackupDetails(backup_id);
      
      if (!backup) {
        return res.status(404).json({ error: 'Sauvegarde non trouvée' });
      }

      res.status(200).json({
        message: 'Détails de la sauvegarde récupérés',
        backup
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des détails de la sauvegarde:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }

    // Obtenir les détails d'une version
  async getVersionDetails(req, res) {
    try {
      const { version_id } = req.params;
      
      if (!version_id) {
        return res.status(400).json({ error: 'ID de version requis' });
      }

      const version = await cleanupService.getVersionDetails(version_id);
      
      if (!version) {
        return res.status(404).json({ error: 'Version non trouvée' });
      }

      res.status(200).json({
        message: 'Détails de la version récupérés',
        version
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des détails de la version:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
}

export default new CleanupController(); 