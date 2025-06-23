// paymentsController.js
import pool from '../../config/database.js';
import "./paymentsModels.js";

// paymentsController.js
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

// Function pour choisir un abonnement
export const chooseSubscription = async (req, res) => {
  const entrepriseId = req.user.entreprise_id; // récupéré via middleware JWT
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

    // 2. Calcul du coût final
    const armoiresIncluses = abonnement.armoires_incluses || 2;
    const supplement = Math.max(armoires_souscrites - armoiresIncluses, 0);
    const fraisSupplementaires = 5000 * Math.ceil(supplement / 2);
    const montantTotal = abonnement.prix_base + fraisSupplementaires;

    // 3. Créer une entrée de paiement en attente
  const paiementResult = await pool.query(
    `INSERT INTO payments (entreprise_id, subscription_id, montant, armoires_souscrites, statut)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *`,
    [entrepriseId, subscription_id, montantTotal, armoires_souscrites, 'en_attente']
  );

    return res.status(201).json({
      message: "Abonnement choisi. Paiement en attente.",
      montant: montantTotal,
      armoires: armoires_souscrites,
      abonnement: abonnement.nom,
      paiement: paiementResult.rows[0]
    });

  } catch (err) {
    console.error("Erreur dans chooseSubscription:", err);
    return res.status(500).json({ error: "Erreur serveur." });
  }
};
