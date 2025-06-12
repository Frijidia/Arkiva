import pool from '../../config/database.js';
// import './favorisModels.js'

export const addFavori = async (req, res) => {
    const { user_id, fichier_id, entreprise_id } = req.body;

    try {
        await pool.query(`
        INSERT INTO favoris (user_id, fichier_id, entreprise_id)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, fichier_id, entreprise_id) DO NOTHING
        `, [user_id, fichier_id, entreprise_id]);

    res.status(200).json({ message: "Fichier ajouté aux favoris." });
    } catch (error) {
        console.error('Erreur ajout favori :', error);
        res.status(500).json({ error: "Erreur serveur." });
    }
};


export const removeFavori = async (req, res) => {
    const { user_id, fichier_id } = req.params;


    try {
        await pool.query(`
      DELETE FROM favoris
      WHERE user_id = $1 AND fichier_id = $2
    `, [user_id, fichier_id]);

        res.status(200).json({ message: "Fichier retiré des favoris." });
    } catch (error) {
        console.error('Erreur suppression favori :', error);
        res.status(500).json({ error: "Erreur serveur." });
    }
};


export const getFavoris = async (req, res) => {
    const {user_id} = req.params;

    try {
        const result = await pool.query(`
      SELECT fichiers.*
      FROM favoris
      JOIN fichiers ON fichiers.fichier_id = favoris.fichier_id
      WHERE favoris.user_id = $1
    `, [user_id]);

        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Erreur liste favoris :', error);
        res.status(500).json({ error: "Erreur serveur." });
    }
};
