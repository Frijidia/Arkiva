// payment_config.js
export const PAYMENT_CONFIG = {
  // Configuration FeexPay
  FEEXPAY: {
    API_KEY: process.env.FEEXPAY_API_KEY,
    SECRET_KEY: process.env.FEEXPAY_SECRET_KEY,
    BASE_URL: process.env.FEEXPAY_BASE_URL || 'https://api.feexpay.com',
    WEBHOOK_SECRET: process.env.FEEXPAY_WEBHOOK_SECRET
  },

  // Configuration Email
  EMAIL: {
    USER: process.env.EMAIL_USER,
    PASS: process.env.EMAIL_PASS,
    FROM: process.env.EMAIL_FROM || 'noreply@arkiva.com'
  },

  // Configuration Application
  APP: {
    BASE_URL: process.env.BASE_URL || 'http://localhost:3000',
    FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:3001'
  },

  // Tarifs des abonnements
  PRICING: {
    MONTHLY_BASE: 5000, // 5000 FCFA
    YEARLY_BASE: 50000, // 50000 FCFA
    EXTRA_ARMORIES_COST: 5000, // 5000 FCFA par tranche de 2 armoires
    ARMORIES_PER_TRANCHE: 2
  },

  // Moyens de paiement supportés
  PAYMENT_METHODS: {
    MTN_MOBILE_MONEY: 'MTN_MOBILE_MONEY',
    MOOV_MONEY: 'MOOV_MONEY',
    CELTIIS_CASH: 'CELTIIS_CASH',
    CARTE_BANCAIRE: 'CARTE_BANCAIRE'
  },

  // Statuts de paiement
  PAYMENT_STATUS: {
    PENDING: 'en_attente',
    SUCCESS: 'succès',
    FAILED: 'échec',
    CANCELLED: 'annulé'
  },

  // Types d'actions d'abonnement
  SUBSCRIPTION_ACTIONS: {
    SUBSCRIPTION: 'souscription',
    RENEWAL: 'renouvellement',
    EXPIRATION: 'expiration',
    CANCELLATION: 'annulation',
    PAYMENT: 'paiement'
  }
};

// Validation des configurations
export const validatePaymentConfig = () => {
  const required = [
    'FEEXPAY_API_KEY',
    'FEEXPAY_SECRET_KEY',
    'EMAIL_USER',
    'EMAIL_PASS'
  ];

  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.warn('Variables d\'environnement manquantes pour les paiements:', missing);
    return false;
  }

  return true;
};

// Générer une référence de transaction unique
export const generateTransactionReference = (paymentId) => {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `ARKIVA_${paymentId}_${timestamp}_${random}`;
};

// Générer un numéro de facture unique
export const generateInvoiceNumber = (paymentId) => {
  const timestamp = Date.now();
  return `FACT-${timestamp}-${paymentId}`;
};

// Calculer le coût des armoires supplémentaires
export const calculateExtraArmoriesCost = (armoiresSouscrites, armoiresIncluses = 2) => {
  const supplement = Math.max(armoiresSouscrites - armoiresIncluses, 0);
  return PAYMENT_CONFIG.PRICING.EXTRA_ARMORIES_COST * Math.ceil(supplement / PAYMENT_CONFIG.PRICING.ARMORIES_PER_TRANCHE);
};

// Calculer le coût total d'un abonnement
export const calculateTotalCost = (prixBase, armoiresSouscrites, armoiresIncluses = 2) => {
  const fraisSupplementaires = calculateExtraArmoriesCost(armoiresSouscrites, armoiresIncluses);
  return prixBase + fraisSupplementaires;
};

export default PAYMENT_CONFIG; 