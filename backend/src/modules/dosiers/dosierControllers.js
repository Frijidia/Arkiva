import pool from '../../config/database.js';
import "./dosierModels.js";


export const CreateDossier = async (req, res) => {
  const { casier_id, nom, user_id } = req.body;

  if (!casier_id || !nom) {
    return res.status(400).json({ error: 'casier_id et nom sont requis' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO dossiers (casier_id, nom, description, user_id) VALUES ($1, $2, $3, $4) RETURNING *',
      [casier_id, nom, " ", user_id]
    );

    res.status(201).json({ message: 'Dossier créé', dossier: result.rows[0] });
  } catch (err) {
    console.error(err);
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
