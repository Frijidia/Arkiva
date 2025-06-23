// payment_config.js
export const PAYMENT_CONFIG = {
  // Configuration FeexPay selon votre .env
  FEEXPAY: {
    API_KEY: process.env.FEEXPAY_API_KEY,
    SHOP_ID: process.env.FEEXPAY_SHOP_ID,
    BASE_URL: 'https://api.feexpay.me',
    MODE: process.env.NODE_ENV === 'production' ? 'LIVE' : 'SANDBOX',
    WEBHOOK_SECRET: process.env.FEEXPAY_WEBHOOK_SECRET
  },

  // Configuration Email selon votre .env
  EMAIL: {
    HOST: process.env.SMTP_HOST,
    PORT: process.env.SMTP_PORT,
    SECURE: process.env.SMTP_SECURE === 'true',
    USER: process.env.SMTP_USER,
    PASS: process.env.SMTP_PASSWORD,
    FROM: process.env.SMTP_FROM
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

  // Moyens de paiement supportés par FeexPay
  PAYMENT_METHODS: {
    MTN_MOBILE_MONEY: {
      name: 'MTN_MOBILE_MONEY',
      network: 'MTN',
      country: 'CI',
      case: 'MOBILE'
    },
    MOOV_MONEY: {
      name: 'MOOV_MONEY',
      network: 'MOOV',
      country: 'CI',
      case: 'MOBILE'
    },
    CELTIIS_CASH: {
      name: 'CELTIIS_CASH',
      network: 'CELTIIS',
      country: 'CI',
      case: 'MOBILE'
    },
    CARTE_BANCAIRE: {
      name: 'CARTE_BANCAIRE',
      case: 'CARD'
    }
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

// Validation des configurations selon votre .env
export const validatePaymentConfig = () => {
  const required = [
    'FEEXPAY_API_KEY',
    'FEEXPAY_SHOP_ID',
    'SMTP_USER',
    'SMTP_PASSWORD'
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

// Configuration FeexPay pour le frontend
export const getFeexPayFrontendConfig = (paymentData) => {
  return {
    token: PAYMENT_CONFIG.FEEXPAY.API_KEY,
    id: PAYMENT_CONFIG.FEEXPAY.SHOP_ID,
    amount: paymentData.montant,
    description: `Abonnement Arkiva - ${paymentData.armoires_souscrites} armoires`,
    callback: () => console.log('Paiement terminé'),
    callback_url: `${PAYMENT_CONFIG.APP.FRONTEND_URL}/payment/success`,
    callback_info: JSON.stringify({ 
      payment_id: paymentData.payment_id, 
      entreprise_id: paymentData.entreprise_id 
    }),
    custom_id: paymentData.custom_id,
    mode: PAYMENT_CONFIG.FEEXPAY.MODE,
    buttonText: "Payer",
    buttonClass: "btn btn-primary",
    defaultValueField: paymentData.defaultValueField || {}
  };
};

// Vérifier si un moyen de paiement est supporté
export const isPaymentMethodSupported = (method) => {
  return Object.keys(PAYMENT_CONFIG.PAYMENT_METHODS).includes(method);
};

// Obtenir la configuration d'un moyen de paiement
export const getPaymentMethodConfig = (method) => {
  return PAYMENT_CONFIG.PAYMENT_METHODS[method] || null;
};

export default PAYMENT_CONFIG; 