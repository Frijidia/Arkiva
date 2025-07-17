import axios from 'axios';

const BASE_URL = 'http://192.168.1.147:3000';
let authToken = '';

async function testSubscription() {
  try {
    console.log('🔍 Test du processus de souscription...');
    
    // 1. Connexion
    console.log('\n1️⃣ Connexion...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'test@arkiva.com',
      password: 'test123'
    });
    
    authToken = loginResponse.data.token;
    console.log('✅ Connexion réussie');
    
    // 2. Récupérer les abonnements disponibles
    console.log('\n2️⃣ Récupération des abonnements...');
    const subscriptionsResponse = await axios.get(`${BASE_URL}/api/payments/subscriptions`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    console.log('📋 Abonnements disponibles:');
    subscriptionsResponse.data.subscriptions.forEach(sub => {
      console.log(`  - ${sub.nom}: ${sub.prix_base} FCFA (${sub.duree} jours, ${sub.armoires_incluses} armoires)`);
    });
    
    // 3. Choisir un abonnement
    console.log('\n3️⃣ Choix d\'un abonnement...');
    const subscriptionId = 1; // Mensuel
    const armoiresSouscrites = 2;
    
    const chooseResponse = await axios.post(`${BASE_URL}/api/payments/choose-subscription`, {
      subscription_id: subscriptionId,
      armoires_souscrites: armoiresSouscrites
    }, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    console.log('✅ Abonnement choisi:');
    console.log(`   - Montant: ${chooseResponse.data.montant} FCFA`);
    console.log(`   - Armoires: ${chooseResponse.data.armoires}`);
    console.log(`   - Payment ID: ${chooseResponse.data.paiement.payment_id}`);
    
    // 4. Traiter le paiement
    console.log('\n4️⃣ Traitement du paiement...');
    const processResponse = await axios.post(`${BASE_URL}/api/payments/process-payment`, {
      payment_id: chooseResponse.data.paiement.payment_id,
      moyen_paiement: 'mobile_money',
      numero_telephone: '22507000000',
      custom_id: null
    }, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    console.log('✅ Paiement traité:');
    console.log(`   - Custom ID: ${processResponse.data.feexpay_data.custom_id}`);
    console.log(`   - Trans Key: ${processResponse.data.feexpay_data.trans_key}`);
    console.log(`   - Amount: ${processResponse.data.feexpay_data.amount}`);
    
    // 5. Vérifier l'état actuel de l'abonnement
    console.log('\n5️⃣ Vérification de l\'abonnement actuel...');
    const currentResponse = await axios.get(`${BASE_URL}/api/payments/current-subscription`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    
    console.log('📊 État de l\'abonnement:');
    console.log(`   - Actif: ${currentResponse.data.subscription.isActive}`);
    console.log(`   - Armoires: ${currentResponse.data.subscription.armoiresSouscrites}`);
    
    console.log('\n🎯 Test terminé avec succès!');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error.response?.data || error.message);
  }
}

testSubscription(); 