import bcrypt from 'bcryptjs';
import pool from './src/config/database.js';

async function testAuth() {
  try {
    console.log('🔍 Test de l\'authentification...');
    
    // 1. Vérifier les utilisateurs existants
    const users = await pool.query('SELECT user_id, email, username, password FROM users LIMIT 5');
    console.log('📋 Utilisateurs existants:');
    users.rows.forEach(user => {
      console.log(`  - ID: ${user.user_id}, Email: ${user.email}, Username: ${user.username}`);
      console.log(`    Password hash: ${user.password.substring(0, 20)}...`);
    });
    
    // 2. Créer un utilisateur de test
    const testEmail = 'test@arkiva.com';
    const testPassword = 'test123';
    const testUsername = 'TestUser';
    
    // Vérifier si l'utilisateur existe déjà
    const existingUser = await pool.query('SELECT * FROM users WHERE email = $1', [testEmail]);
    
    if (existingUser.rows.length === 0) {
      console.log('➕ Création d\'un utilisateur de test...');
      const hashedPassword = await bcrypt.hash(testPassword, 10);
      
      await pool.query(
        `INSERT INTO users (email, password, username, role, entreprise_id) 
         VALUES ($1, $2, $3, $4, $5)`,
        [testEmail, hashedPassword, testUsername, 'admin', 1]
      );
      
      console.log('✅ Utilisateur de test créé avec succès!');
      console.log(`   Email: ${testEmail}`);
      console.log(`   Password: ${testPassword}`);
    } else {
      console.log('ℹ️ Utilisateur de test existe déjà');
    }
    
    // 3. Tester l'authentification
    console.log('\n🧪 Test d\'authentification...');
    const testUser = await pool.query('SELECT * FROM users WHERE email = $1', [testEmail]);
    
    if (testUser.rows.length > 0) {
      const user = testUser.rows[0];
      const isMatch = await bcrypt.compare(testPassword, user.password);
      console.log(`   Mot de passe correct: ${isMatch ? '✅' : '❌'}`);
    }
    
    console.log('\n🎯 Informations de connexion pour l\'application:');
    console.log(`   Email: ${testEmail}`);
    console.log(`   Password: ${testPassword}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

testAuth();