import pool from '../../config/database.js';
import "./dosierModels.js";


export const CreateDossier = async (req, res) => {
  const { casier_id, nom, user_id } = req.body;

  if (!casier_id || !nom) {
    return res.status(400).json({ error: 'casier_id et nom sont requis' });
  }

  try {
    // 1. Vérifie si le casier existe et récupère l’armoire
    const casierResult = await pool.query(
      `SELECT armoire_id FROM casiers WHERE casier_id = $1`,
      [casier_id]
    );

    if (casierResult.rowCount === 0) {
      return res.status(404).json({ error: "Casier non trouvé" });
    }

    const armoire_id = casierResult.rows[0].armoire_id;

    // 2. Récupère la capacité maximale de l’armoire
    const armoireResult = await pool.query(
      `SELECT taille_max FROM armoires WHERE armoire_id = $1`,
      [armoire_id]
    );

    if (armoireResult.rowCount === 0) {
      return res.status(404).json({ error: "Armoire associée non trouvée" });
    }

    const taille_max = parseInt(armoireResult.rows[0].taille_max) || 0;

    // 3. Calcule l’espace déjà utilisé
    const espaceResult = await pool.query(
      `
      SELECT COALESCE(SUM(f.taille), 0) AS total_octets
      FROM fichiers f
      JOIN dossiers d ON f.dossier_id = d.dossier_id
      JOIN casiers c ON d.casier_id = c.casier_id
      WHERE c.armoire_id = $1 AND f.is_deleted = false
      `,
      [armoire_id]
    );

    const espaceUtilise = parseInt(espaceResult.rows[0].total_octets) || 0;

    if (espaceUtilise >= taille_max) {
      return res.status(400).json({ error: "L'armoire est pleine. Impossible de créer un nouveau dossier." });
    }

    // 4. Crée le dossier
    const result = await pool.query(
      `INSERT INTO dossiers (casier_id, nom, description, user_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [casier_id, nom, " ", user_id]
    );

    res.status(201).json({ message: 'Dossier créé', dossier: result.rows[0] });

  } catch (err) {
    console.error('Erreur création dossier :', err);
    res.status(500).json({ error: 'Erreur serveur lors de la création du dossier' });
  }
};



export const GetDossiersByCasier = async (req, res) => {
  const { casier_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM dossiers WHERE casier_id = $1 ORDER BY dossier_id ASC',
      [casier_id]
    );

    res.status(200).json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des dossiers' });
  }
};



export const DeleteDossier = async (req, res) => {
  const { dossier_id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM dossiers WHERE dossier_id = $1 RETURNING *',
      [dossier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }

    res.status(200).json({ message: 'Dossier supprimé avec succès', dossier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression du dossier' });
  }
};




export const RenameDossier = async (req, res) => {
  const { dossier_id } = req.params;
  const { nom } = req.body;

  if (!nom) {
    return res.status(400).json({ error: 'Le nouveau nom est requis' });
  }

  try {
    const result = await pool.query(
      'UPDATE dossiers SET nom = $1 WHERE dossier_id = $2 RETURNING *',
      [nom, dossier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }

    res.status(200).json({ message: 'Nom du dossier mis à jour', dossier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du renommage du dossier' });
  }
};



export const getDossierById = async (req, res) => {
  const { dossier_id } = req.params;

  if (!dossier_id) return res.status(400).json({ error: "ID du dossier requis" });

  try {
    const result = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1 AND is_deleted = false', [dossier_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Dossier introuvable" });
    }

    res.status(200).json({ dossier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération du dossier" });
  }
};



export const getDossierCountByCasierId = async (req, res) => {
  const { casier_id } = req.params;

  if (!casier_id) return res.status(400).json({ error: "ID du casier requis" });

  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM dossiers WHERE casier_id = $1',
      [casier_id]
    );

    res.status(200).json({ casier_id, nombre_dossiers: parseInt(result.rows[0].count) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors du comptage des dossiers" });
  }
};



// Déplacement d'un dossier vers un autre casier
export const deplacerDossier = async (req, res) => {
  const { id } = req.params; // ID du dossier à déplacer
  const { nouveau_casier_id } = req.body;

  try {
    // 1. Récupérer l’armoire du nouveau casier
    const casierResult = await pool.query(
      `SELECT armoire_id FROM casiers WHERE casier_id = $1`,
      [nouveau_casier_id]
    );

    if (casierResult.rowCount === 0) {
      return res.status(404).json({ error: "Nouveau casier non trouvé" });
    }

    const nouvelleArmoireId = casierResult.rows[0].armoire_id;

    // 2. Récupérer la taille maximale de l'armoire cible
    const armoireResult = await pool.query(
      `SELECT taille_max FROM armoires WHERE armoire_id = $1`,
      [nouvelleArmoireId]
    );

    const tailleMax = parseInt(armoireResult.rows[0].taille_max);

    // 3. Récupérer l'espace utilisé par l’armoire (uniquement fichiers non supprimés)
    const espaceUtiliseResult = await pool.query(`
      SELECT COALESCE(SUM(f.taille), 0) AS total
      FROM fichiers f
      JOIN dossiers d ON f.dossier_id = d.dossier_id
      JOIN casiers c ON d.casier_id = c.casier_id
      WHERE c.armoire_id = $1 AND f.is_deleted = false
    `, [nouvelleArmoireId]);

    const espaceUtilise = parseInt(espaceUtiliseResult.rows[0].total);

    // 4. Calculer l’espace occupé par le dossier à déplacer
    const tailleDossierResult = await pool.query(`
      SELECT COALESCE(SUM(taille), 0) AS total FROM fichiers 
      WHERE dossier_id = $1 AND is_deleted = false
    `, [id]);

    const tailleDossier = parseInt(tailleDossierResult.rows[0].total);

    // 5. Vérification de capacité
    if (espaceUtilise + tailleDossier > tailleMax) {
      return res.status(400).json({ error: "L'armoire cible n’a pas assez d’espace pour accueillir ce dossier." });
    }

    // 6. Déplacement du dossier
    const result = await pool.query(
      `UPDATE dossiers SET casier_id = $1 WHERE dossier_id = $2 RETURNING *`,
      [nouveau_casier_id, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Dossier non trouvé" });
    }

    res.status(200).json({ message: "Dossier déplacé avec succès", dossier: result.rows[0] });
  } catch (err) {
    console.error("Erreur déplacement dossier :", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
};
