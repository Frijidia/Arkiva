import pool from '../../config/database.js';

// Vérifier si une entreprise a un abonnement actif
export const checkSubscriptionStatus = async (entrepriseId) => {
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
      return { hasActiveSubscription: false, canAccess: false, reason: 'Entreprise introuvable' };
    }

    const entreprise = result.rows[0];
    const isExpired = entreprise.date_expiration && new Date(entreprise.date_expiration) < new Date();

    return {
      hasActiveSubscription: !isExpired,
      canAccess: !isExpired,
      isExpired,
      dateExpiration: entreprise.date_expiration,
      armoiresSouscrites: entreprise.armoires_souscrites || 0,
      armoireLimit: entreprise.armoire_limit || 0,
      daysUntilExpiration: entreprise.date_expiration ? 
        Math.ceil((new Date(entreprise.date_expiration) - new Date()) / (1000 * 60 * 60 * 24)) : null
    };
  } catch (err) {
    console.error('Erreur vérification statut abonnement:', err);
    return { hasActiveSubscription: false, canAccess: false, reason: 'Erreur serveur' };
  }
};

// Vérifier si une entreprise peut créer des armoires
export const canCreateArmoires = async (entrepriseId, nombreArmoires = 1) => {
  try {
    const status = await checkSubscriptionStatus(entrepriseId);
    
    if (!status.canAccess) {
      return { allowed: false, reason: 'Abonnement expiré' };
    }

    // Compter les armoires existantes
    const armoiresResult = await pool.query(
      'SELECT COUNT(*) as count FROM armoires WHERE entreprise_id = $1 AND is_deleted = FALSE',
      [entrepriseId]
    );

    const armoiresExistantes = parseInt(armoiresResult.rows[0].count);
    const armoiresApresCreation = armoiresExistantes + nombreArmoires;

    if (armoiresApresCreation > status.armoiresSouscrites) {
      return { 
        allowed: false, 
        reason: `Limite d'armoires dépassée. Vous avez souscrit à ${status.armoiresSouscrites} armoires.`,
        armoiresExistantes,
        armoiresSouscrites: status.armoiresSouscrites
      };
    }

    return { allowed: true, armoiresExistantes, armoiresSouscrites: status.armoiresSouscrites };
  } catch (err) {
    console.error('Erreur vérification création armoires:', err);
    return { allowed: false, reason: 'Erreur serveur' };
  }
};

// Vérifier si une entreprise peut scanner/téléverser des documents
export const canUploadDocuments = async (entrepriseId) => {
  try {
    const status = await checkSubscriptionStatus(entrepriseId);
    
    if (!status.canAccess) {
      return { allowed: false, reason: 'Abonnement expiré. Veuillez renouveler votre abonnement.' };
    }

    return { allowed: true };
  } catch (err) {
    console.error('Erreur vérification upload documents:', err);
    return { allowed: false, reason: 'Erreur serveur' };
  }
};

// Vérifier si une entreprise peut accéder aux casiers
export const canAccessCasiers = async (entrepriseId) => {
  try {
    const status = await checkSubscriptionStatus(entrepriseId);
    
    if (!status.canAccess) {
      return { allowed: false, reason: 'Abonnement expiré. Tous les casiers sont fermés.' };
    }

    return { allowed: true };
  } catch (err) {
    console.error('Erreur vérification accès casiers:', err);
    return { allowed: false, reason: 'Erreur serveur' };
  }
};

// Middleware pour vérifier l'abonnement avant les actions sensibles
export const subscriptionMiddleware = (action) => {
  return async (req, res, next) => {
    try {
      const entrepriseId = req.user.entreprise_id;
      let checkResult;

      switch (action) {
        case 'upload':
          checkResult = await canUploadDocuments(entrepriseId);
          break;
        case 'armoires':
          const { nombreArmoires = 1 } = req.body;
          checkResult = await canCreateArmoires(entrepriseId, nombreArmoires);
          break;
        case 'casiers':
          checkResult = await canAccessCasiers(entrepriseId);
          break;
        default:
          checkResult = await checkSubscriptionStatus(entrepriseId);
      }

      if (!checkResult.allowed) {
        return res.status(403).json({
          error: checkResult.reason,
          subscriptionRequired: true,
          action: action
        });
      }

      // Ajouter les informations d'abonnement à la requête
      req.subscriptionInfo = checkResult;
      next();
    } catch (err) {
      console.error('Erreur middleware abonnement:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  };
};

// Tâche cron pour désactiver les abonnements expirés
export const disableExpiredSubscriptions = async () => {
  try {
    const result = await pool.query(
      `UPDATE entreprises 
       SET is_active = FALSE 
       WHERE date_expiration < NOW() AND is_active = TRUE`
    );

    if (result.rowCount > 0) {
      console.log(`${result.rowCount} abonnements expirés désactivés`);
      
      // Logger les désactivations
      await pool.query(
        `INSERT INTO subscription_history (entreprise_id, type_action, ancien_statut, nouveau_statut, details)
         SELECT e.entreprise_id, 'expiration', 'actif', 'expiré', 
                json_build_object('date_expiration', e.date_expiration)
         FROM entreprises e
         WHERE e.date_expiration < NOW() AND e.is_active = FALSE`
      );
    }
  } catch (err) {
    console.error('Erreur désactivation abonnements expirés:', err);
  }
};

// Calculer le coût de renouvellement automatique
export const calculateRenewalCost = async (entrepriseId) => {
  try {
    const status = await checkSubscriptionStatus(entrepriseId);
    
    if (!status.isExpired) {
      return { error: 'Abonnement encore actif' };
    }

    // Récupérer le dernier paiement pour connaître le nombre d'armoires
    const lastPaymentResult = await pool.query(
      `SELECT p.armoires_souscrites, s.prix_base, s.duree, s.armoires_incluses
       FROM payments p
       JOIN subscription s ON p.subscription_id = s.subscription_id
       WHERE p.entreprise_id = $1
       ORDER BY p.date_paiement DESC
       LIMIT 1`,
      [entrepriseId]
    );

    if (lastPaymentResult.rowCount === 0) {
      return { error: 'Aucun historique de paiement trouvé' };
    }

    const lastPayment = lastPaymentResult.rows[0];
    const armoiresIncluses = lastPayment.armoires_incluses || 2;
    const supplement = Math.max(lastPayment.armoires_souscrites - armoiresIncluses, 0);
    const fraisSupplementaires = 5000 * Math.ceil(supplement / 2);
    const montantTotal = lastPayment.prix_base + fraisSupplementaires;

    return {
      montant: montantTotal,
      armoires: lastPayment.armoires_souscrites,
      duree: lastPayment.duree,
      prixBase: lastPayment.prix_base,
      fraisSupplementaires
    };
  } catch (err) {
    console.error('Erreur calcul coût renouvellement:', err);
    return { error: 'Erreur serveur' };
  }
};

export default {
  checkSubscriptionStatus,
  canCreateArmoires,
  canUploadDocuments,
  canAccessCasiers,
  subscriptionMiddleware,
  disableExpiredSubscriptions,
  calculateRenewalCost
}; 