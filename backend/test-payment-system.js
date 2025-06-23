#!/usr/bin/env node

/**
 * Script de test pour le système de paiement Arkiva
 * Usage: node test-payment-system.js
 */

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import http from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🚀 Démarrage du système de test de paiement Arkiva...\n');

// Configuration
const PORT = process.env.PORT || 3000;
const TEST_URL = `http://localhost:${PORT}/api/payments/test`;

// Fonction pour vérifier si le serveur est prêt
function checkServerReady() {
    return new Promise((resolve, reject) => {
        const req = http.get(TEST_URL, (res) => {
            if (res.statusCode === 200) {
                resolve(true);
            } else {
                reject(new Error(`Serveur répond avec le statut ${res.statusCode}`));
            }
        });

        req.on('error', (err) => {
            reject(err);
        });

        req.setTimeout(5000, () => {
            req.destroy();
            reject(new Error('Timeout lors de la vérification du serveur'));
        });
    });
}

// Fonction pour ouvrir le navigateur
function openBrowser(url) {
    const platform = process.platform;
    let command;

    switch (platform) {
        case 'darwin':
            command = 'open';
            break;
        case 'win32':
            command = 'start';
            break;
        default:
            command = 'xdg-open';
    }

    const child = spawn(command, [url], { stdio: 'ignore' });
    child.on('error', (err) => {
        console.log(`⚠️  Impossible d'ouvrir le navigateur automatiquement: ${err.message}`);
        console.log(`🌐 Ouvrez manuellement: ${url}`);
    });
}

// Fonction principale
async function main() {
    try {
        console.log('📋 Instructions de test:');
        console.log('1. Le serveur va démarrer sur le port', PORT);
        console.log('2. L\'interface de test s\'ouvrira automatiquement');
        console.log('3. Testez toutes les fonctionnalités du module de paiement');
        console.log('4. Vérifiez les logs du serveur pour le debugging\n');

        // Démarrer le serveur
        console.log('🔄 Démarrage du serveur...');
        const server = spawn('npm', ['start'], {
            cwd: __dirname,
            stdio: 'inherit',
            shell: true
        });

        // Attendre que le serveur soit prêt
        console.log('⏳ Attente du démarrage du serveur...');
        let attempts = 0;
        const maxAttempts = 30;

        while (attempts < maxAttempts) {
            try {
                await new Promise(resolve => setTimeout(resolve, 2000));
                await checkServerReady();
                console.log('✅ Serveur prêt!');
                break;
            } catch (err) {
                attempts++;
                if (attempts >= maxAttempts) {
                    console.error('❌ Impossible de démarrer le serveur');
                    process.exit(1);
                }
                console.log(`⏳ Tentative ${attempts}/${maxAttempts}...`);
            }
        }

        // Ouvrir le navigateur
        console.log('🌐 Ouverture de l\'interface de test...');
        openBrowser(TEST_URL);

        console.log('\n🎉 Interface de test ouverte!');
        console.log('\n📝 Fonctionnalités à tester:');
        console.log('   • Récupération des abonnements');
        console.log('   • Choix d\'un abonnement');
        console.log('   • Traitement des paiements');
        console.log('   • Test des webhooks FeexPay');
        console.log('   • Historique des abonnements');
        console.log('   • Statut de l\'abonnement actuel');
        console.log('\n🔧 Pour arrêter: Ctrl+C');

        // Gérer l'arrêt propre
        process.on('SIGINT', () => {
            console.log('\n🛑 Arrêt du serveur...');
            server.kill('SIGINT');
            process.exit(0);
        });

    } catch (error) {
        console.error('❌ Erreur:', error.message);
        process.exit(1);
    }
}

// Démarrer le script
main(); 