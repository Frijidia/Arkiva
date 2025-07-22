import pool from '../../config/database.js';

// Middleware pour vérifier si l'entreprise a un abonnement actif
export const checkSubscriptionStatus = async (req, res, next) => {
  try {
    const entrepriseId = req.user.entreprise_id;
    
    // Vérifier si l'entreprise a un abonnement actif
    const result = await pool.query(
      `SELECT e.*, p.date_expiration, p.statut as payment_status
       FROM entreprises e
       LEFT JOIN payments p ON e.entreprise_id = p.entreprise_id
       WHERE e.entreprise_id = $1
       ORDER BY p.date_expiration DESC
       LIMIT 1`,
      [entrepriseId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ 
        error: "Entreprise introuvable",
        subscriptionRequired: true 
      });
    }

    const entreprise = result.rows[0];
    const isExpired = !entreprise.date_expiration || new Date(entreprise.date_expiration) < new Date();
    const hasActivePayment = entreprise.payment_status === 'succès';

    // Si pas d'abonnement actif, bloquer l'accès
    if (isExpired || !hasActivePayment) {
      return res.status(403).json({
        error: "Abonnement requis",
        subscriptionRequired: true,
        message: "Vous devez avoir un abonnement actif pour accéder à cette fonctionnalité",
        isExpired,
        hasActivePayment,
        expirationDate: entreprise.date_expiration
      });
    }

    // Ajouter les infos d'abonnement à la requête
    req.subscription = {
      isActive: true,
      expirationDate: entreprise.date_expiration,
      daysUntilExpiration: Math.ceil((new Date(entreprise.date_expiration) - new Date()) / (1000 * 60 * 60 * 24))
    };

    next();
  } catch (error) {
    console.error('Erreur vérification abonnement:', error);
    res.status(500).json({ 
      error: 'Erreur serveur',
      subscriptionRequired: true 
    });
  }
};

// Middleware pour vérifier l'accès aux armoires spécifiques
export const checkArmoireAccess = async (req, res, next) => {
  try {
    const entrepriseId = req.user.entreprise_id;
    const armoireId = req.params.armoireId || req.body.armoire_id;

    if (!armoireId) {
      return res.status(400).json({ error: "ID de l'armoire requis" });
    }

    // Vérifier si l'armoire appartient à l'entreprise
    const armoireResult = await pool.query(
      'SELECT * FROM armoires WHERE armoire_id = $1 AND entreprise_id = $2',
      [armoireId, entrepriseId]
    );

    if (armoireResult.rowCount === 0) {
      return res.status(404).json({ error: "Armoire introuvable" });
    }

    // Vérifier l'abonnement
    const subscriptionResult = await pool.query(
      `SELECT p.date_expiration, p.statut as payment_status
       FROM payments p
       WHERE p.entreprise_id = $1 AND p.statut = 'succès'
       ORDER BY p.date_expiration DESC
       LIMIT 1`,
      [entrepriseId]
    );

    const isExpired = subscriptionResult.rowCount === 0 || 
                     new Date(subscriptionResult.rows[0].date_expiration) < new Date();

    if (isExpired) {
      return res.status(403).json({
        error: "Accès bloqué",
        subscriptionRequired: true,
        message: "Votre abonnement a expiré. Renouvelez votre abonnement pour accéder à vos armoires."
      });
    }

    next();
  } catch (error) {
    console.error('Erreur vérification accès armoire:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// Middleware pour vérifier l'accès aux dossiers
export const checkDossierAccess = async (req, res, next) => {
  try {
    const entrepriseId = req.user.entreprise_id;
    const dossierId = req.params.dossierId || req.body.dossier_id;

    if (!dossierId) {
      return res.status(400).json({ error: "ID du dossier requis" });
    }

    // Vérifier si le dossier appartient à l'entreprise
    const dossierResult = await pool.query(
      `SELECT d.* FROM dossiers d
       JOIN armoires a ON d.armoire_id = a.armoire_id
       WHERE d.dossier_id = $1 AND a.entreprise_id = $2`,
      [dossierId, entrepriseId]
    );

    if (dossierResult.rowCount === 0) {
      return res.status(404).json({ error: "Dossier introuvable" });
    }

    // Vérifier l'abonnement
    const subscriptionResult = await pool.query(
      `SELECT p.date_expiration, p.statut as payment_status
       FROM payments p
       WHERE p.entreprise_id = $1 AND p.statut = 'succès'
       ORDER BY p.date_expiration DESC
       LIMIT 1`,
      [entrepriseId]
    );

    const isExpired = subscriptionResult.rowCount === 0 || 
                     new Date(subscriptionResult.rows[0].date_expiration) < new Date();

    if (isExpired) {
      return res.status(403).json({
        error: "Accès bloqué",
        subscriptionRequired: true,
        message: "Votre abonnement a expiré. Renouvelez votre abonnement pour accéder à vos dossiers."
      });
    }

    next();
  } catch (error) {
    console.error('Erreur vérification accès dossier:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// Middleware pour vérifier l'accès aux fichiers
export const checkFichierAccess = async (req, res, next) => {
  console.log('checkFichierAccess params:', req.params, req.body);
  try {
    const entrepriseId = req.user.entreprise_id;
    const fichierId = req.params.fichier_id || req.body.fichier_id;

    if (!fichierId) {
      console.error('ID du fichier manquant dans checkFichierAccess');
      return res.status(400).json({ error: "ID du fichier requis" });
    }

    // Vérifier si le fichier appartient à l'entreprise
    const fichierResult = await pool.query(
      `SELECT f.* FROM fichiers f
       JOIN dossiers d ON f.dossier_id = d.dossier_id
       JOIN casiers c ON d.cassier_id = c.cassier_id
       JOIN armoires a ON c.armoire_id = a.armoire_id
       WHERE f.fichier_id = $1 AND a.entreprise_id = $2`,
      [fichierId, entrepriseId]
    );

    const fichier = fichierResult.rows[0];
    if (!fichier) {
      console.error('Fichier undefined dans checkFichierAccess');
      return res.status(404).json({ error: "Fichier introuvable" });
    }

    // Vérifier l'abonnement
    const subscriptionResult = await pool.query(
      `SELECT p.date_expiration, p.statut as payment_status
       FROM payments p
       WHERE p.entreprise_id = $1 AND p.statut = 'succès'
       ORDER BY p.date_expiration DESC
       LIMIT 1`,
      [entrepriseId]
    );

    const isExpired = subscriptionResult.rowCount === 0 || 
                     new Date(subscriptionResult.rows[0].date_expiration) < new Date();

    if (isExpired) {
      return res.status(403).json({
        error: "Accès bloqué",
        subscriptionRequired: true,
        message: "Votre abonnement a expiré. Renouvelez votre abonnement pour accéder à vos fichiers."
      });
    }

    next();
  } catch (error) {
    console.error('Erreur vérification accès fichier:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
}; 