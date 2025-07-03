// paymentsController.js
import pool from '../../config/database.js';
//import "./paymentsModels.js";
import nodemailer from 'nodemailer';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';

// Configuration email selon votre .env
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD
  }
});

// Configuration FeexPay selon leur documentation
const FEEXPAY_CONFIG = {
  apiKey: process.env.FEEXPAY_API_KEY,
  shopId: process.env.FEEXPAY_SHOP_ID,
  baseUrl: process.env.FEEXPAY_BASE_URL || 'https://api.feexpay.me',
  mode: process.env.NODE_ENV === 'production' ? 'LIVE' : 'SANDBOX'
};

// Récupérer les abonnements disponibles
export const getSubscriptions = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT subscription_id, nom, prix_base, duree, armoires_incluses, description
       FROM subscription
       WHERE status = 'actif'
       ORDER BY prix_base ASC`
    );

    res.status(200).json({
      subscriptions: result.rows
    });

  } catch (err) {
    console.error('Erreur lors de la récupération des abonnements:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// Choisir un abonnement et calculer le coût
export const chooseSubscription = async (req, res) => {
  const entrepriseId = req.user.entreprise_id;
  const { subscription_id, armoires_souscrites } = req.body;

  // Sécurité : vérifier que le nombre d'armoires est au moins 2
  if (armoires_souscrites < 2) {
    return res.status(400).json({ error: "Vous devez souscrire à au moins 2 armoires." });
  }

  try {
    // 1. Vérifier que l'abonnement existe et est actif
    const subResult = await pool.query(
      'SELECT * FROM subscription WHERE subscription_id = $1 AND status = $2',
      [subscription_id, 'actif']
    );

    if (subResult.rowCount === 0) {
      return res.status(404).json({ error: "Abonnement introuvable ou inactif." });
    }

    const abonnement = subResult.rows[0];

    // 2. Calcul du coût final selon les spécifications
    const armoiresIncluses = abonnement.armoires_incluses || 2;
    const supplement = Math.max(armoires_souscrites - armoiresIncluses, 0);
    const fraisSupplementaires = 5000 * Math.ceil(supplement / 2); // 5000 FCFA par tranche de 2 armoires
    const montantTotal = abonnement.prix_base + fraisSupplementaires;

    // 3. Calculer la date d'expiration
    const dateExpiration = new Date();
    dateExpiration.setDate(dateExpiration.getDate() + abonnement.duree);

    // 4. Créer une entrée de paiement en attente
    const payment_id = uuidv4();
    const paiementResult = await pool.query(
      `INSERT INTO payments (payment_id, entreprise_id, subscription_id, montant, armoires_souscrites, statut, date_expiration)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [payment_id, entrepriseId, subscription_id, montantTotal, armoires_souscrites, 'en_attente', dateExpiration]
    );

    // 5. Logger l'action
    await pool.query(
      `INSERT INTO subscription_history (entreprise_id, payment_id, type_action, nouveau_statut, details)
       VALUES ($1, $2, $3, $4, $5)`,
      [entrepriseId, paiementResult.rows[0].payment_id, 'souscription', 'en_attente', 
       JSON.stringify({ montant: montantTotal, armoires: armoires_souscrites })]
    );

    return res.status(201).json({
      message: "Abonnement choisi. Paiement en attente.",
      montant: montantTotal,
      armoires: armoires_souscrites,
      abonnement: abonnement.nom,
      paiement: paiementResult.rows[0],
      date_expiration: dateExpiration
    });

  } catch (err) {
    console.error("Erreur dans chooseSubscription:", err);
    return res.status(500).json({ error: "Erreur serveur." });
  }
};

// Effectuer le paiement via FeexPay
export const processPayment = async (req, res) => {
  const { payment_id, moyen_paiement, numero_telephone, custom_id } = req.body;
  const entrepriseId = req.user.entreprise_id;

  try {
    // 1. Vérifier que le paiement existe et appartient à l'entreprise
    const paymentResult = await pool.query(
      'SELECT * FROM payments WHERE payment_id = $1 AND entreprise_id = $2 AND statut = $3',
      [payment_id, entrepriseId, 'en_attente']
    );

    if (paymentResult.rowCount === 0) {
      return res.status(404).json({ error: "Paiement introuvable ou déjà traité." });
    }

    const payment = paymentResult.rows[0];

    // 2. Générer une clé de transaction aléatoire de 15 caractères
    const trans_key = Math.random().toString(36).substring(2, 17);

    // 2.1. Générer un custom_id unique si non fourni
    const generatedCustomId = custom_id || `ARKIVA_${payment_id}_${Date.now()}`;

    // 3. Préparer les données pour le SDK FeexPay Flutter
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:37811';
    const redirecturl = `${frontendUrl}/payment/success`;
    console.log('FeexPay redirecturl utilisé:', redirecturl);
    const feexpayData = {
      // Données requises par le SDK FeexPay
      id: FEEXPAY_CONFIG.shopId,
      token: FEEXPAY_CONFIG.apiKey,
      amount: Math.round(Number(payment.montant)),
      trans_key: trans_key,
      redirecturl: redirecturl,
      // IMPORTANT : custom_id à la racine du payload
      custom_id: generatedCustomId,
      callback_info: JSON.stringify({ 
        payment_id, 
        entreprise_id: entrepriseId,
        custom_id: generatedCustomId
      }),
      // Données supplémentaires pour le suivi
      payment_id: payment_id,
      entreprise_id: entrepriseId,
      moyen_paiement: moyen_paiement,
      numero_telephone: numero_telephone,
      // Configuration selon le mode
      mode: FEEXPAY_CONFIG.mode,
      description: `Abonnement Arkiva - ${payment.armoires_souscrites} armoires`
    };

    // 4. Mettre à jour le paiement avec la clé de transaction
    await pool.query(
      `UPDATE payments 
       SET feexpay_trans_key = $1, moyen_paiement = $2, custom_id = $3
       WHERE payment_id = $4`,
      [trans_key, moyen_paiement, feexpayData.custom_id, payment_id]
    );

    // 5. Logger l'action
    await pool.query(
      `INSERT INTO subscription_history (entreprise_id, payment_id, type_action, ancien_statut, nouveau_statut, details)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [entrepriseId, payment_id, 'initiation_paiement', 'en_attente', 'en_attente', 
       JSON.stringify({ trans_key, moyen_paiement, montant: payment.montant })]
    );

    // 6. Retourner les données pour le SDK Flutter
    return res.status(200).json({
      success: true,
      message: "Paiement initié. Utilisez ces données avec le SDK FeexPay Flutter.",
      feexpay_data: {
        id: feexpayData.id,
        token: feexpayData.token,
        amount: feexpayData.amount,
        trans_key: feexpayData.trans_key,
        redirecturl: feexpayData.redirecturl,
        callback_info: feexpayData.callback_info
      },
      payment_info: {
        payment_id: payment_id,
        montant: payment.montant,
        armoires_souscrites: payment.armoires_souscrites,
        date_expiration: payment.date_expiration
      }
    });

  } catch (err) {
    console.error("Erreur dans processPayment:", err);
    return res.status(500).json({ error: "Erreur serveur." });
  }
};

// Webhook FeexPay pour confirmer les paiements
export const feexPayWebhook = async (req, res) => {
  try {
    // Log complet du corps de la requête
    console.log("[FeexPay] Webhook body complet:", JSON.stringify(req.body, null, 2));

    if (!req.body) {
      console.error("[FeexPay] Webhook: req.body est undefined");
      return res.status(400).json({ error: "Body de la requête manquant" });
    }

    const { reference, status, transaction_id } = req.body;
    // Extraction du custom_id depuis callback_info si nécessaire
    let custom_id = req.body.custom_id;
    if (!custom_id && req.body.callback_info) {
      try {
        const callbackInfoObj = typeof req.body.callback_info === 'string'
          ? JSON.parse(req.body.callback_info)
          : req.body.callback_info;
        custom_id = callbackInfoObj.custom_id;
        console.log('[FeexPay] custom_id extrait depuis callback_info:', custom_id);
      } catch (e) {
        console.error('[FeexPay] Erreur parsing callback_info:', e, req.body.callback_info);
      }
    }

    // Extraction du payment_id (alphanumérique) depuis custom_id
    let paymentId = null;
    if (custom_id) {
      // Extrait la partie centrale du custom_id (ex: ARKIVA_6824ae4d4e09a6935400f8dc_1751562560272)
      const match = custom_id.match(/^ARKIVA_([^_]+)_/);
      if (match) {
        paymentId = match[1];
      }
    }
    console.log(`[FeexPay] PaymentId extrait (string):`, paymentId);

    if (!paymentId) {
      console.error("[FeexPay] Payment ID introuvable dans custom_id:", custom_id);
      return res.status(400).json({ error: "Payment ID introuvable dans custom_id" });
    }

    // Vérification du statut actuel
    const currentStatus = await pool.query(
      'SELECT statut FROM payments WHERE payment_id = $1',
      [paymentId]
    );
    console.log("[FeexPay] Statut actuel:", currentStatus.rows[0]?.statut);

    // Normalisation du statut
    const normalizedStatus = String(status).toLowerCase();
    console.log("[FeexPay] Statut normalisé:", normalizedStatus);

    if ([
      'success', 'completed', 'approved', 'successful'
    ].includes(normalizedStatus)) {
      const updateResult = await pool.query(
        `UPDATE payments 
         SET statut = $1, 
             reference_transaction = $2,
             updated_at = CURRENT_TIMESTAMP
         WHERE payment_id = $3 AND statut = 'en_attente'
         RETURNING payment_id, statut, reference_transaction`,
        ['succès', transaction_id, paymentId]
      );

      console.log("[FeexPay] Résultat update:", {
        rowCount: updateResult.rowCount,
        updatedPayment: updateResult.rows[0]
      });

      if (updateResult.rowCount === 0) {
        console.warn(`[FeexPay] Aucun paiement en attente mis à jour pour payment_id=${paymentId}`);
        // Vérifions si le paiement existe
        const payment = await pool.query(
          'SELECT payment_id, statut FROM payments WHERE payment_id = $1',
          [paymentId]
        );
        console.log("[FeexPay] État actuel du paiement:", payment.rows[0]);
      } else {
        console.log(`[FeexPay] Paiement ${paymentId} marqué comme succès`);
        
        try {
          const paymentResult = await pool.query(
            'SELECT entreprise_id FROM payments WHERE payment_id = $1',
            [paymentId]
          );
          const entrepriseId = paymentResult.rows[0]?.entreprise_id;
          
          if (entrepriseId) {
            const invoice = await generateInvoice(paymentId, entrepriseId);
            await sendInvoiceEmail(invoice, entrepriseId);
            console.log(`[FeexPay] Facture ${invoice.numero_facture} générée et envoyée`);
          } else {
            console.error("[FeexPay] Impossible de trouver l'entreprise_id pour le paiement", paymentId);
          }
        } catch (invoiceError) {
          console.error('[FeexPay] Erreur facture:', invoiceError);
        }
      }
    } else {
      console.log(`[FeexPay] Statut non reconnu comme succès:`, status);
      const updateResult = await pool.query(
        `UPDATE payments SET statut = $1 WHERE payment_id = $2 AND statut = 'en_attente'`,
        ['échec', paymentId]
      );
      console.log(`[FeexPay] Paiement marqué comme échec:`, updateResult.rowCount, 'ligne(s) modifiée(s)');
    }

    res.status(200).json({ message: "Webhook traité avec succès" });
  } catch (err) {
    console.error("[FeexPay] Erreur webhook:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// Générer une facture
const generateInvoice = async (paymentId, entrepriseId) => {
  try {
    const paymentResult = await pool.query(
      `SELECT p.*, s.nom as subscription_name, e.nom as entreprise_nom, e.email
       FROM payments p
       JOIN subscription s ON p.subscription_id = s.subscription_id
       JOIN entreprises e ON p.entreprise_id = e.entreprise_id
       WHERE p.payment_id = $1`,
      [paymentId]
    );

    if (paymentResult.rowCount === 0) {
      throw new Error("Paiement introuvable");
    }

    const payment = paymentResult.rows[0];
    const numeroFacture = `FACT-${Date.now()}-${paymentId}`;
    const montantHT = parseInt(payment.montant);
    const tva = 0; // Pas de TVA selon les spécifications
    const montantTTC = montantHT + tva;

    const invoiceResult = await pool.query(
      `INSERT INTO invoices (payment_id, entreprise_id, numero_facture, montant_ht, montant_ttc, tva, date_echeance)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [paymentId, entrepriseId, numeroFacture, montantHT, montantTTC, tva, payment.date_expiration]
    );

    return invoiceResult.rows[0];
  } catch (err) {
    console.error("Erreur génération facture:", err);
    throw err;
  }
};

// Envoyer la facture par email
const sendInvoiceEmail = async (invoice, entrepriseId) => {
  try {
    const entrepriseResult = await pool.query(
      'SELECT nom, email FROM entreprises WHERE entreprise_id = $1',
      [entrepriseId]
    );

    if (entrepriseResult.rowCount === 0) {
      throw new Error("Entreprise introuvable");
    }

    const entreprise = entrepriseResult.rows[0];

    const mailOptions = {
      from: process.env.SMTP_FROM,
      to: entreprise.email,
      subject: `Facture Arkiva - ${invoice.numero_facture}`,
      html: `
        <h2>Facture Arkiva</h2>
        <p>Bonjour ${entreprise.nom},</p>
        <p>Votre facture pour votre abonnement Arkiva a été générée.</p>
        <p><strong>Numéro de facture:</strong> ${invoice.numero_facture}</p>
        <p><strong>Montant:</strong> ${invoice.montant_ttc} FCFA</p>
        <p><strong>Date d'émission:</strong> ${new Date(invoice.date_emission).toLocaleDateString()}</p>
        <p>Merci de votre confiance.</p>
      `
    };

    await transporter.sendMail(mailOptions);

    // Marquer la facture comme envoyée
    await pool.query(
      'UPDATE invoices SET email_envoye = TRUE WHERE invoice_id = $1',
      [invoice.invoice_id]
    );

  } catch (err) {
    console.error("Erreur envoi email facture:", err);
  }
};

// Récupérer l'historique des abonnements
export const getSubscriptionHistory = async (req, res) => {
  const entrepriseId = req.user.entreprise_id;

  try {
    const result = await pool.query(
      `SELECT p.*, s.nom as subscription_name, i.numero_facture, i.montant_ttc
       FROM payments p
       JOIN subscription s ON p.subscription_id = s.subscription_id
       LEFT JOIN invoices i ON p.payment_id = i.payment_id
       WHERE p.entreprise_id = $1
       ORDER BY p.created_at DESC`,
      [entrepriseId]
    );

    res.status(200).json({
      history: result.rows
    });

  } catch (err) {
    console.error('Erreur récupération historique:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// Vérifier le statut de l'abonnement actuel
export const getCurrentSubscription = async (req, res) => {
  const entrepriseId = req.user.entreprise_id;

  try {
    // Debug: Vérifier la structure des tables
    console.log('🔍 Vérification de la structure des tables...');
    
    const dossiersStructure = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'dossiers' 
      ORDER BY ordinal_position
    `);
    console.log('📋 Structure table dossiers:', dossiersStructure.rows);
    
    const casiersStructure = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'casiers' 
      ORDER BY ordinal_position
    `);
    console.log('📋 Structure table casiers:', casiersStructure.rows);

    const result = await pool.query(
      `SELECT e.*, p.date_expiration, p.armoires_souscrites, p.statut as payment_status
       FROM entreprises e
       LEFT JOIN payments p ON e.entreprise_id = p.entreprise_id
       WHERE e.entreprise_id = $1
       ORDER BY p.date_expiration DESC
       LIMIT 1`,
      [entrepriseId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Entreprise introuvable" });
    }

    const entreprise = result.rows[0];
    const isExpired = entreprise.date_expiration && new Date(entreprise.date_expiration) < new Date();
    const hasActivePayment = entreprise.payment_status === 'succès';
    const isSubscriptionActive = !isExpired && hasActivePayment;

    // Compter les armoires de l'entreprise
    const armoiresResult = await pool.query(
      'SELECT COUNT(*) as total_armoires FROM armoires WHERE entreprise_id = $1',
      [entrepriseId]
    );

    // Compter les dossiers - Utiliser la structure réelle détectée
    const dossiersResult = await pool.query(
      `SELECT COUNT(*) as total_dossiers FROM dossiers d
       JOIN casiers c ON d.cassier_id = c.cassier_id
       JOIN armoires a ON c.armoire_id = a.armoire_id
       WHERE a.entreprise_id = $1`,
      [entrepriseId]
    );

    // Compter les fichiers
    const fichiersResult = await pool.query(
      `SELECT COUNT(*) as total_fichiers FROM fichiers f
       JOIN dossiers d ON f.dossier_id = d.dossier_id
       JOIN casiers c ON d.cassier_id = c.cassier_id
       JOIN armoires a ON c.armoire_id = a.armoire_id
       WHERE a.entreprise_id = $1`,
      [entrepriseId]
    );

    res.status(200).json({
      entreprise,
      subscription: {
        isActive: isSubscriptionActive,
        isExpired,
        hasActivePayment,
        expirationDate: entreprise.date_expiration,
        daysUntilExpiration: entreprise.date_expiration ? 
          Math.ceil((new Date(entreprise.date_expiration) - new Date()) / (1000 * 60 * 60 * 24)) : null,
        armoiresSouscrites: entreprise.armoires_souscrites || 0
      },
      usage: {
        totalArmoires: parseInt(armoiresResult.rows[0].total_armoires),
        totalDossiers: parseInt(dossiersResult.rows[0].total_dossiers),
        totalFichiers: parseInt(fichiersResult.rows[0].total_fichiers)
      },
      access: {
        canAccessArmoires: isSubscriptionActive,
        canAccessDossiers: isSubscriptionActive,
        canAccessFichiers: isSubscriptionActive,
        canUpload: isSubscriptionActive,
        canCreate: isSubscriptionActive
      }
    });

  } catch (err) {
    console.error('Erreur vérification abonnement:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// Fonctions utilitaires FeexPay selon leur documentation
const callFeexPayAPI = async (payload) => {
  try {
    // Selon leur documentation, FeexPay utilise une approche différente
    // Ils fournissent un SDK JavaScript/React plutôt qu'une API REST directe
    // Pour l'intégration backend, nous devons utiliser leur approche webhook
    
    // Créer une URL de paiement FeexPay
    const feexpayUrl = `${FEEXPAY_CONFIG.baseUrl}/payment`;
    
    // Pour l'instant, nous simulons la réponse
    // En production, vous devrez implémenter l'intégration selon leur SDK
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          success: true,
          reference: payload.custom_id,
          transaction_id: `TXN_${Date.now()}`,
          payment_url: `${feexpayUrl}?token=${payload.token}&id=${payload.id}&amount=${payload.amount}&callback=${encodeURIComponent(payload.callback)}&custom_id=${payload.custom_id}&description=${encodeURIComponent(payload.description)}&mode=${payload.mode}`
        });
      }, 1000);
    });
    
    // TODO: Implémenter la vraie intégration selon leur SDK
    // Vous devrez peut-être utiliser leur SDK JavaScript côté frontend
    // et communiquer avec le backend via webhooks
    
  } catch (error) {
    console.error('Erreur appel FeexPay:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

const verifyFeexPaySignature = (req) => {
  // À implémenter selon la documentation FeexPay
  // Ils mentionnent une vérification de signature pour les webhooks
  return true;
};
