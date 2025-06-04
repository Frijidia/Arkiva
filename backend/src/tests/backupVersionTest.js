import backupModel from '../modules/backup/backupModel.js';
import versionService from '../modules/backup/versionService.js';
import restoreService from '../modules/backup/restoreService.js';
import fs from 'fs';
import path from 'path';

// ID de test pour l'utilisateur
const TEST_USER_ID = '00000000-0000-0000-0000-000000000000';

async function runTests() {
    console.log('Démarrage des tests de sauvegarde et versionnement...\n');

    try {
        // Test 1: Création d'une sauvegarde de fichier
        console.log('Test 1: Création d\'une sauvegarde de fichier');
        const testFileContent = Buffer.from('Contenu de test pour la sauvegarde');
        const testFilePath = path.join(__dirname, '../../uploads/test_backup.zip');
        
        // Créer un fichier de test
        await fs.promises.writeFile(testFilePath, testFileContent);
        
        const backupData = {
            type: 'fichier',
            cible_id: '11111111-1111-1111-1111-111111111111',
            chemin_sauvegarde: testFilePath,
            contenu_json: {
                nom: 'test_file.txt',
                taille: testFileContent.length,
                type_mime: 'text/plain'
            },
            declenche_par_id: TEST_USER_ID
        };

        const backup = await backupModel.createBackup(backupData);
        console.log('✓ Sauvegarde créée avec succès:', backup.id);

        // Test 2: Création d'une version
        console.log('\nTest 2: Création d\'une version');
        const versionMetadata = {
            version_number: 1,
            nom: 'test_file.txt',
            type_mime: 'text/plain',
            taille: testFileContent.length
        };

        const version = await versionService.createNewVersion(
            backupData.cible_id,
            testFileContent,
            versionMetadata,
            TEST_USER_ID
        );
        console.log('✓ Version créée avec succès:', version.id);

        // Test 3: Récupération de l'historique des versions
        console.log('\nTest 3: Récupération de l\'historique des versions');
        const versionHistory = await versionService.getVersionHistory(backupData.cible_id);
        console.log('✓ Historique des versions récupéré:', versionHistory.length, 'versions trouvées');

        // Test 4: Comparaison de versions
        if (versionHistory.length >= 2) {
            console.log('\nTest 4: Comparaison de versions');
            const comparison = await versionService.compareVersions(
                versionHistory[0].id,
                versionHistory[1].id
            );
            console.log('✓ Comparaison de versions effectuée:', comparison);
        }

        // Test 5: Restauration de sauvegarde
        console.log('\nTest 5: Restauration de sauvegarde');
        const restoreResult = await restoreService.restoreBackup(backup.id, TEST_USER_ID);
        console.log('✓ Restauration effectuée:', restoreResult);

        // Nettoyage
        console.log('\nNettoyage des fichiers de test...');
        if (fs.existsSync(testFilePath)) {
            await fs.promises.unlink(testFilePath);
        }

        console.log('\nTous les tests ont été exécutés avec succès!');

    } catch (error) {
        console.error('\n❌ Erreur lors des tests:', error);
    }
}

// Exécuter les tests
runTests(); 