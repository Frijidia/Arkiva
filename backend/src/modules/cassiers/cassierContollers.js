import pool from '../../config/database.js';


// création d’un casier
export const CreateCasier = async (req, res) => {
    const { armoire_id, user_id } = req.body;
    const sous_titre = "";

    if (!armoire_id || !user_id) {
        return res.status(400).json({ error: 'armoire_id et user_id requis' });
    }

    try {
        // 1. Récupérer le nom de l’armoire
        const armoireResult = await pool.query(
            'SELECT nom FROM armoires WHERE armoire_id = $1',
            [armoire_id]
        );

        if (armoireResult.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }

        const nomArmoire = armoireResult.rows[0].nom;

        // 2. Extraire le numéro de l’armoire depuis son nom (ex: "Armoire 2" → 2)
        const numeroArmoire = parseInt(nomArmoire.match(/\d+/)[0]);

        // 3. Calculer la plage de noms pour les casiers de cette armoire
        const min = (numeroArmoire - 1) * 10 + 1;
        const max = numeroArmoire * 10;

        // 4. Récupérer tous les noms de casiers existants pour cette armoire
        const casiersResult = await pool.query(
            'SELECT nom FROM casiers WHERE armoire_id = $1',
            [armoire_id]
        );

        const nomsExistant = casiersResult.rows.map(c => parseInt(c.nom.replace('C', '')));

        // 5. Trouver le premier numéro libre dans la plage
        let numeroLibre = null;
        for (let i = min; i <= max; i++) {
            if (!nomsExistant.includes(i)) {
                numeroLibre = i;
                break;
            }
        }

        if (!numeroLibre) {
            return res.status(400).json({ error: 'Limite de 10 casiers atteinte pour cette armoire' });
        }

        const nomCasier = `C${numeroLibre}`;

        // 6. Insérer le casier
        const insert = await pool.query(
            'INSERT INTO casiers (armoire_id, nom, sous_titre, user_id) VALUES ($1, $2, $3, $4) RETURNING *',
            [armoire_id, nomCasier, sous_titre, user_id]
        );

        res.status(201).json({ message: 'Casier créé', casier: insert.rows[0] });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur serveur' });
    }
};



export const GetAllCasiers = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT * FROM casiers
      ORDER BY CAST(regexp_replace(nom, '\\D', '', 'g') AS INTEGER)
    `);
    res.status(200).json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des armoires' });
  }
};



export const GetCasiersByArmoire = async (req, res) => {
  const { armoire_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM casiers WHERE armoire_id = $1 ORDER BY CAST(regexp_replace(nom, \'\\D\', \'\', \'g\') AS INTEGER)',
      [armoire_id]
    );

    res.status(200).json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des casiers' });
  }
};


export const RenameCasier = async (req, res) => {
    const { cassier_id } = req.params;
    const { sous_titre } = req.body;

    try {
        const update = await pool.query(
            'UPDATE casiers SET sous_titre = $1 WHERE cassier_id = $2 RETURNING *',
            [sous_titre, cassier_id]
        );

        if (update.rowCount === 0) {
            return res.status(404).json({ error: 'Cassier non trouvé' });
        }

        res.status(200).json({ message: 'Sous-titre du casier mis à jour', cassier: update.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la mise à jour du casier' });
    }
};


export const DeleteCasier = async (req, res) => {
    const { cassier_id } = req.params;

    try {
        const deletion = await pool.query('DELETE FROM casiers WHERE cassier_id = $1 RETURNING *', [cassier_id]);

        if (deletion.rowCount === 0) {
            return res.status(404).json({ error: 'Cassier non trouvé' });
        }

        res.status(200).json({ message: 'Cassier supprimé avec succès', cassier: deletion.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la suppression du casier' });
    }
};


export const getCasierById = async (req, res) => {
  const { casier_id } = req.params;

  if (!casier_id) return res.status(400).json({ error: "ID du casier requis" });

  try {
    const result = await pool.query('SELECT * FROM casiers WHERE casier_id = $1', [casier_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Casier introuvable" });
    }

    res.status(200).json({ casier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération du casier" });
  }
};
