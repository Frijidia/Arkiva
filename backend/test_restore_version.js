// Script de test pour la restauration de versions
import restoreService from './src/modules/restore/restoreService.js';
import versionService from './src/modules/versions/versionService.js';

// Test de restauration de version
const testRestoreVersion = async () => {
    try {
        console.log('🧪 Test de restauration de version...');
        
        // Simuler une restauration de version
        const versionId = 'test-version-id';
        const userId = 1;
        
        const result = await restoreService.restoreVersion(versionId, userId);
        console.log('✅ Restauration de version réussie:', result);
        
    } catch (error) {
        console.error('❌ Erreur lors du test de restauration:', error);
    }
};

// Test de restauration de sauvegarde
const testRestoreBackup = async () => {
    try {
        console.log('🧪 Test de restauration de sauvegarde...');
        
        // Simuler une restauration de sauvegarde
        const backupId = 'test-backup-id';
        const userId = 1;
        
        const result = await restoreService.restoreBackup(backupId, userId);
        console.log('✅ Restauration de sauvegarde réussie:', result);
        
    } catch (error) {
        console.error('❌ Erreur lors du test de restauration:', error);
    }
};

// Exécuter les tests
console.log('🚀 Démarrage des tests de restauration...');
testRestoreVersion();
testRestoreBackup(); 