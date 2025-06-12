
import pool from '../../config/database.js';


/**
 * 1. recuperer les fichiers par tag
 */

export async function getFilesByTag(req, res) {
  const { tag_id} = req.params;

  try {
    const query = `
     SELECT fichiers.*, tags.name AS tag_nom
        FROM fichiers
        JOIN fichier_tags ON fichiers.fichier_id = fichier_tags.fichier_id
        JOIN tags ON fichier_tags.tag_id = tags.tag_id
        WHERE fichier_tags.tag_id = $1
        ORDER BY fichiers.nom;
    `;
    const result = await pool.query(query, [tag_id]);
    res.json(result.rows);
  } catch (error) {
    console.error('Erreur lors de la récupération des fichiers par tag :', error);
    res.status(500).json({
      error: 'Erreur serveur lors de la récupération des fichiers', details: error.message  // Ajout du détail de l'erreur ici
    });
  }
}


/**
 * 2. recuperer les fichiers par contenue ocr 
 */

export const searchFichiersByOcrContent = async (req, res) => {
  const { searchTerm } = req.params;

  if (!searchTerm) {
    return res.status(400).json({ error: "Le paramètre 'searchTerm' est obligatoire." });
  }

  try {
    const query = `
      SELECT 
        fichiers.*,
        armoires.nom AS armoire,
        casiers.nom AS casier,
        dossiers.nom AS dossier
      FROM fichiers
      JOIN dossiers ON fichiers.dossier_id = dossiers.dossier_id
      JOIN casiers ON dossiers.casier_id = casiers.cassier_id
      JOIN armoires ON casiers.armoire_id = armoires.armoire_id 
      WHERE fichiers.nom ILIKE '%' || $1 || '%' OR fichiers.contenu_ocr ILIKE '%' || $1 || '%'

    `;

    const { rows } = await pool.query(query, [searchTerm]);

    // Ajouter chemin de localisation dans chaque fichier
    const fichiersAvecChemin = rows.map(row => ({
      ...row,
      chemin: `${row.armoire} > ${row.casier} > ${row.dossier}`
    }));

    res.status(200).json(fichiersAvecChemin);
  } catch (error) {
    console.error('Erreur recherche OCR:', error);
    res.status(500).json({ error: "Erreur lors de la recherche dans le contenu OCR." });
  }
};



/**
 * 3. recuperer les fichiers par nom des element
 */
export const searchFichiersByFlexibleLocation = async (req, res) => {
  const { armoire, casier, dossier, nom } = req.query;

  try {
    let conditions = [];
    let values = [];
    let index = 1;

    if (armoire) {
      conditions.push(`armoires.nom = $${index++}`);
      values.push(armoire);
    }

    if (casier) {
      conditions.push(`casiers.nom = $${index++}`);
      values.push(casier);
    }

    if (dossier) {
      conditions.push(`dossiers.nom = $${index++}`);
      values.push(dossier);
    }

    if (nom) {
      conditions.push(`fichiers.nom ILIKE $${index++}`);
      values.push(`%${nom}%`); // recherche partielle
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : '';

    const query = `
      SELECT fichiers.*, 
        armoires.nom AS armoire_nom,
        casiers.nom AS casier_nom,
        dossiers.nom AS dossier_nom
      FROM fichiers
      JOIN dossiers ON fichiers.dossier_id = dossiers.dossier_id
      JOIN casiers ON dossiers.casier_id = casiers.cassier_id
      JOIN armoires ON casiers.armoire_id = armoires.armoire_id 
      ${whereClause}
    `;

    const { rows } = await pool.query(query, values);

    const fichiersAvecChemin = rows.map(file => {
      const cheminParts = [];

      if (file.armoire_nom) cheminParts.push(file.armoire_nom);
      if (file.casier_nom) cheminParts.push(file.casier_nom);
      if (file.dossier_nom) cheminParts.push(file.dossier_nom);

      return {
        ...file,
        chemin: cheminParts.join(' > ')
      };
    });

    return res.status(200).json(fichiersAvecChemin);
  } catch (error) {
    console.error("Erreur lors de la recherche flexible par localisation :", error);
    res.status(500).json({ error: "Erreur serveur." });
  }
};



/**
 * 4. recuperer les fichiers par Date
*/

export const getFichiersByDate = async (req, res) => {
  const { debut, fin } = req.query;
  if (!debut || !fin) {
    return res.status(400).json({ error: "Les dates 'debut' et 'fin' sont obligatoires." });
  }

  try {
    const result = await pool.query(`
      SELECT * FROM fichiers WHERE created_at BETWEEN $1 AND $2
    `, [debut, fin]);

    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Erreur filtre date :', error);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
};
