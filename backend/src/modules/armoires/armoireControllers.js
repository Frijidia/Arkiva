import pool from '../../config/database.js';

// Création d'une armoire

export const CreateArmoire = async (req, res) => {
    const { user_id, entreprise_id } = req.body;
    const sous_titre = "";
    if (!user_id) return res.status(400).json({ error: 'user_id requis' });

    try {
        // 1. Récupérer la limite d’armoires de l’entreprise
        const limitResult = await pool.query(
            'SELECT armoire_limit FROM entreprises WHERE entreprise_id = $1',
            [entreprise_id]
        );
        const armoireLimit = parseInt(limitResult.rows[0].armoire_limit || 2);

        // 2. Compter toutes les armoires, même supprimées
        const totalResult = await pool.query(
            'SELECT COUNT(*) FROM armoires WHERE entreprise_id = $1',
            [entreprise_id]
        );
        const totalCount = parseInt(totalResult.rows[0].count);

        if (totalCount >= armoireLimit) {
            return res.status(403).json({ error: "Limite d’armoires atteinte. Veuillez souscrire pour plus." });
        }

        // 3. Trouver le premier numéro de nom libre
        const nomsResult = await pool.query(
            `SELECT nom FROM armoires WHERE entreprise_id = $1`,
            [entreprise_id]
        );

        const existingNumbers = nomsResult.rows
            .map(row => parseInt(row.nom.replace('Armoire ', '')))
            .filter(num => !isNaN(num));

        let numeroLibre = 1;
        for (; existingNumbers.includes(numeroLibre); numeroLibre++) { }

        const nomArmoire = `Armoire ${numeroLibre}`;

        // 4. Insérer
        const result = await pool.query(
            'INSERT INTO armoires (user_id, sous_titre, nom, entreprise_id) VALUES ($1, $2, $3, $4) RETURNING *',
            [user_id, sous_titre, nomArmoire, entreprise_id]
        );

        res.status(201).json({ message: 'Armoire créée', armoire: result.rows[0] });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la création de l’armoire' });
    }
};


export const GetAllArmoires = async (req, res) => {
    const { entreprise_id } = req.params;

    try {
        const result = await pool.query(`
  SELECT * FROM armoires
  WHERE entreprise_id = $1
  ORDER BY CAST(regexp_replace(nom, '\\D', '', 'g') AS INTEGER)
`, [entreprise_id]);
        res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la récupération des armoires' });
    }
};


export const RenameArmoire = async (req, res) => {
    const { armoire_id } = req.params;
    const { sous_titre } = req.body;

    try {
        const update = await pool.query(
            'UPDATE armoires SET sous_titre = $1 WHERE armoire_id = $2 RETURNING *',
            [sous_titre, armoire_id]
        );

        if (update.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }

        res.status(200).json({ message: 'Sous-titre mis à jour', armoire: update.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la mise à jour de l’armoire' });
    }
};


export const DeleteArmoire = async (req, res) => {
    const { armoire_id } = req.params;

    try {
        const deletion = await pool.query('DELETE FROM armoires WHERE armoire_id = $1 RETURNING *', [armoire_id]);

        if (deletion.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }

        res.status(200).json({ message: 'Armoire supprimée avec succès', armoire: deletion.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la suppression de l’armoire' });
    }
};



export const getArmoireById = async (req, res) => {
  const { armoire_id } = req.params;

  if (!armoire_id) return res.status(400).json({ error: "ID de l'armoire requis" });

  try {
    const result = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [armoire_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Armoire introuvable" });
    }

    res.status(200).json({ armoire: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération de l'armoire" });
  }
};
