// paymentsController.js
import pool from '../../config/database.js';
import "./paymentsModels.js";
import nodemailer from 'nodemailer';
import axios from 'axios';

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
    const paiementResult = await pool.query(
      `INSERT INTO payments (entreprise_id, subscription_id, montant, armoires_souscrites, statut, date_expiration)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [entrepriseId, subscription_id, montantTotal, armoires_souscrites, 'en_attente', dateExpiration]
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

    // 2. Préparer la requête FeexPay selon leur documentation
    const feexpayPayload = {
      id: FEEXPAY_CONFIG.shopId,
      amount: payment.montant,
      token: FEEXPAY_CONFIG.apiKey,
      callback: `${process.env.BASE_URL}/api/payments/webhook`,
      callback_url: `${process.env.FRONTEND_URL}/payment/success`,
      callback_info: JSON.stringify({ payment_id, entreprise_id: entrepriseId }),
      custom_id: custom_id || `ARKIVA_${payment_id}_${Date.now()}`,
      description: `Abonnement Arkiva - ${payment.armoires_souscrites} armoires`,
      mode: FEEXPAY_CONFIG.mode
    };

    // 3. Adapter selon le moyen de paiement selon leur documentation
    switch (moyen_paiement) {
      case 'MTN_MOBILE_MONEY':
        feexpayPayload.case = 'MOBILE';
        feexpayPayload.defaultValueField = { 
          'country_iban': 'CI', 
          'network': 'MTN' 
        };
        if (numero_telephone) {
          feexpayPayload.defaultValueField.phone = numero_telephone;
        }
        break;
      case 'MOOV_MONEY':
        feexpayPayload.case = 'MOBILE';
        feexpayPayload.defaultValueField = { 
          'country_iban': 'CI', 
          'network': 'MOOV' 
        };
        if (numero_telephone) {
          feexpayPayload.defaultValueField.phone = numero_telephone;
        }
        break;
      case 'CELTIIS_CASH':
        feexpayPayload.case = 'MOBILE';
        feexpayPayload.defaultValueField = { 
          'country_iban': 'CI', 
          'network': 'CELTIIS' 
        };
        if (numero_telephone) {
          feexpayPayload.defaultValueField.phone = numero_telephone;
        }
        break;
      case 'CARTE_BANCAIRE':
        feexpayPayload.case = 'CARD';
        break;
      default:
        return res.status(400).json({ error: "Moyen de paiement non supporté." });
    }

    // 4. Appeler l'API FeexPay selon leur documentation
    const feexpayResponse = await callFeexPayAPI(feexpayPayload);

    if (feexpayResponse.success) {
      // 5. Mettre à jour le paiement
      await pool.query(
        `UPDATE payments 
         SET statut = $1, feexpay_reference = $2, moyen_paiement = $3, reference_transaction = $4
         WHERE payment_id = $5`,
        ['succès', feexpayResponse.reference, moyen_paiement, feexpayResponse.transaction_id, payment_id]
      );

      // 6. Générer la facture
      const invoice = await generateInvoice(payment_id, entrepriseId);

      // 7. Envoyer la facture par email
      await sendInvoiceEmail(invoice, entrepriseId);

      // 8. Logger l'action
      await pool.query(
        `INSERT INTO subscription_history (entreprise_id, payment_id, type_action, ancien_statut, nouveau_statut, details)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [entrepriseId, payment_id, 'paiement', 'en_attente', 'succès', 
         JSON.stringify({ moyen_paiement, feexpay_reference: feexpayResponse.reference })]
      );

      return res.status(200).json({
        message: "Paiement effectué avec succès",
        transaction_id: feexpayResponse.transaction_id,
        invoice: invoice,
        feexpay_data: feexpayResponse
      });
    } else {
      // Échec du paiement
      await pool.query(
        `UPDATE payments SET statut = $1 WHERE payment_id = $2`,
        ['échec', payment_id]
      );

      return res.status(400).json({ 
        error: "Échec du paiement. Veuillez réessayer.",
        details: feexpayResponse.error
      });
    }

  } catch (err) {
    console.error("Erreur dans processPayment:", err);
    return res.status(500).json({ error: "Erreur serveur." });
  }
};

// Webhook FeexPay pour confirmer les paiements
export const feexPayWebhook = async (req, res) => {
  const { reference, status, transaction_id, custom_id } = req.body;

  try {
    // Vérifier la signature FeexPay (à implémenter selon leur documentation)
    if (!verifyFeexPaySignature(req)) {
      return res.status(401).json({ error: "Signature invalide" });
    }

    // Extraire payment_id de custom_id
    const paymentId = custom_id ? custom_id.split('_')[1] : null;

    if (!paymentId) {
      return res.status(400).json({ error: "Payment ID introuvable dans custom_id" });
    }

    if (status === 'success' || status === 'SUCCESS') {
      await pool.query(
        `UPDATE payments SET statut = $1, reference_transaction = $2 WHERE payment_id = $3`,
        ['succès', transaction_id, paymentId]
      );
    } else {
      await pool.query(
        `UPDATE payments SET statut = $1 WHERE payment_id = $2`,
        ['échec', paymentId]
      );
    }

    res.status(200).json({ message: "Webhook traité avec succès" });
  } catch (err) {
    console.error("Erreur webhook FeexPay:", err);
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
    const montantHT = payment.montant;
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

    res.status(200).json({
      entreprise,
      isExpired,
      canAccess: !isExpired,
      daysUntilExpiration: entreprise.date_expiration ? 
        Math.ceil((new Date(entreprise.date_expiration) - new Date()) / (1000 * 60 * 60 * 24)) : null
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
