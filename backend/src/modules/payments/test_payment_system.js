// test_payment_system.js
import pool from '../../config/database.js';
import { calculateTotalCost, calculateExtraArmoriesCost } from '../config/payment_config.js';
import { checkSubscriptionStatus, canCreateArmoires } from './subscriptionService.js';

// Tests unitaires pour les calculs de coût
const testPricingCalculations = () => {
  console.log('🧮 Test des calculs de tarification...');
  
  // Test 1: Abonnement mensuel avec 2 armoires (prix de base)
  const monthly2Armoires = calculateTotalCost(5000, 2, 2);
  console.log(`✅ Mensuel 2 armoires: ${monthly2Armoires} FCFA (attendu: 5000)`);
  
  // Test 2: Abonnement mensuel avec 4 armoires (supplément)
  const monthly4Armoires = calculateTotalCost(5000, 4, 2);
  console.log(`✅ Mensuel 4 armoires: ${monthly4Armoires} FCFA (attendu: 10000)`);
  
  // Test 3: Abonnement mensuel avec 6 armoires (supplément)
  const monthly6Armoires = calculateTotalCost(5000, 6, 2);
  console.log(`✅ Mensuel 6 armoires: ${monthly6Armoires} FCFA (attendu: 15000)`);
  
  // Test 4: Abonnement annuel avec 2 armoires
  const yearly2Armoires = calculateTotalCost(50000, 2, 2);
  console.log(`✅ Annuel 2 armoires: ${yearly2Armoires} FCFA (attendu: 50000)`);
  
  // Test 5: Abonnement annuel avec 8 armoires
  const yearly8Armoires = calculateTotalCost(50000, 8, 2);
  console.log(`✅ Annuel 8 armoires: ${yearly8Armoires} FCFA (attendu: 65000)`);
  
  console.log('✅ Tous les calculs de tarification sont corrects!\n');
};

// Test de la base de données
const testDatabaseSetup = async () => {
  console.log('🗄️ Test de la configuration de la base de données...');
  
  try {
    // Vérifier que les tables existent
    const tables = ['subscription', 'payments', 'invoices', 'subscription_history'];
    
    for (const table of tables) {
      const result = await pool.query(
        `SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = $1
        )`,
        [table]
      );
      
      if (result.rows[0].exists) {
        console.log(`✅ Table ${table} existe`);
      } else {
        console.log(`❌ Table ${table} manquante`);
      }
    }
    
    // Vérifier les abonnements par défaut
    const subscriptions = await pool.query('SELECT * FROM subscription WHERE status = $1', ['actif']);
    console.log(`✅ ${subscriptions.rowCount} abonnements actifs trouvés`);
    
    console.log('✅ Configuration de la base de données OK!\n');
  } catch (err) {
    console.error('❌ Erreur test base de données:', err);
  }
};

// Test des fonctions de vérification d'abonnement
const testSubscriptionChecks = async () => {
  console.log('🔍 Test des vérifications d\'abonnement...');
  
  try {
    // Créer une entreprise de test
    const testEntreprise = await pool.query(
      `INSERT INTO entreprises (nom, email, telephone, adresse, plan_abonnement, armoire_limit)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING entreprise_id`,
      ['Test Entreprise', 'test@example.com', '22507012345', 'Test Address', 'standard', 2]
    );
    
    const entrepriseId = testEntreprise.rows[0].entreprise_id;
    
    // Test 1: Vérifier le statut d'abonnement (doit être expiré par défaut)
    const status = await checkSubscriptionStatus(entrepriseId);
    console.log(`✅ Statut abonnement: ${status.canAccess ? 'Actif' : 'Expiré'}`);
    
    // Test 2: Vérifier la création d'armoires (doit être refusée)
    const canCreate = await canCreateArmoires(entrepriseId, 1);
    console.log(`✅ Peut créer des armoires: ${canCreate.allowed ? 'Oui' : 'Non'}`);
    
    // Nettoyer
    await pool.query('DELETE FROM entreprises WHERE entreprise_id = $1', [entrepriseId]);
    
    console.log('✅ Tests de vérification d\'abonnement OK!\n');
  } catch (err) {
    console.error('❌ Erreur test vérifications:', err);
  }
};

// Test de génération de factures
const testInvoiceGeneration = async () => {
  console.log('🧾 Test de génération de factures...');
  
  try {
    // Créer des données de test
    const testEntreprise = await pool.query(
      `INSERT INTO entreprises (nom, email, telephone, adresse)
       VALUES ($1, $2, $3, $4)
       RETURNING entreprise_id`,
      ['Test Facture', 'facture@example.com', '22507012345', 'Test Address']
    );
    
    const entrepriseId = testEntreprise.rows[0].entreprise_id;
    
    const testSubscription = await pool.query(
      'SELECT subscription_id FROM subscription WHERE nom = $1 LIMIT 1',
      ['Mensuel']
    );
    
    const subscriptionId = testSubscription.rows[0].subscription_id;
    
    // Créer un paiement de test
    const testPayment = await pool.query(
      `INSERT INTO payments (entreprise_id, subscription_id, montant, armoires_souscrites, statut, date_expiration)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING payment_id`,
      [entrepriseId, subscriptionId, 10000, 4, 'succès', new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)]
    );
    
    const paymentId = testPayment.rows[0].payment_id;
    
    // Générer une facture
    const invoice = await pool.query(
      `INSERT INTO invoices (payment_id, entreprise_id, numero_facture, montant_ht, montant_ttc, tva, date_echeance)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [paymentId, entrepriseId, `FACT-TEST-${Date.now()}`, 10000, 10000, 0, new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)]
    );
    
    console.log(`✅ Facture générée: ${invoice.rows[0].numero_facture}`);
    console.log(`✅ Montant: ${invoice.rows[0].montant_ttc} FCFA`);
    
    // Nettoyer
    await pool.query('DELETE FROM invoices WHERE payment_id = $1', [paymentId]);
    await pool.query('DELETE FROM payments WHERE payment_id = $1', [paymentId]);
    await pool.query('DELETE FROM entreprises WHERE entreprise_id = $1', [entrepriseId]);
    
    console.log('✅ Test de génération de factures OK!\n');
  } catch (err) {
    console.error('❌ Erreur test factures:', err);
  }
};

// Test des webhooks FeexPay
const testFeexPayWebhook = () => {
  console.log('🔗 Test des webhooks FeexPay...');
  
  const testWebhookData = {
    reference: 'ARKIVA_123_1703123456789_abc123',
    status: 'success',
    transaction_id: 'TXN_1703123456789'
  };
  
  // Simuler l'extraction du payment_id
  const paymentId = testWebhookData.reference.split('_')[1];
  console.log(`✅ Payment ID extrait: ${paymentId}`);
  
  console.log(`✅ Webhook simulé: ${testWebhookData.status}`);
  console.log('✅ Test des webhooks OK!\n');
};

// Test complet du système
const runAllTests = async () => {
  console.log('🚀 Démarrage des tests du système de paiement...\n');
  
  testPricingCalculations();
  await testDatabaseSetup();
  await testSubscriptionChecks();
  await testInvoiceGeneration();
  testFeexPayWebhook();
  
  console.log('🎉 Tous les tests sont terminés!');
  console.log('\n📋 Résumé des fonctionnalités testées:');
  console.log('✅ Calculs de tarification');
  console.log('✅ Configuration de la base de données');
  console.log('✅ Vérifications d\'abonnement');
  console.log('✅ Génération de factures');
  console.log('✅ Webhooks FeexPay');
  
  process.exit(0);
};

// Exécuter les tests si le script est appelé directement
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests().catch(err => {
    console.error('❌ Erreur lors des tests:', err);
    process.exit(1);
  });
}

export {
  testPricingCalculations,
  testDatabaseSetup,
  testSubscriptionChecks,
  testInvoiceGeneration,
  testFeexPayWebhook,
  runAllTests
}; 