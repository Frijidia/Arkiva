import pool from '../../config/database.js';
import s3 from '../../config/aws.js';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import mime from "mime-types";

// import fs from 'fs/promises';


// GET fichiers par dossier_id
export const getFichiersByDossierId = async (req, res) => {
  const { dossier_id } = req.params;

  if (!dossier_id) {
    return res.status(400).json({ error: "ID du dossier requis" });
  }

  try {
    const result = await pool.query(
      'SELECT * FROM fichiers WHERE dossier_id = $1 ORDER BY fichier_id DESC',
      [dossier_id]
    );

    res.status(200).json({ fichiers: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération des fichiers" });
  }
};

// supprimer fichier

export const deleteFichier = async (req, res) => {
  const { fichier_id } = req.params;

  try {
    const result = await pool.query('SELECT chemin FROM fichiers WHERE fichier_id = $1', [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }

    const filePath = result.rows[0].chemin;

    // Supprimer le fichier physique
    await fs.unlink(filePath);

    // Supprimer de la base
    await pool.query('DELETE FROM fichiers WHERE fichier_id = $1', [fichier_id]);

    res.status(200).json({ message: "Fichier supprimé avec succès" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la suppression du fichier" });
  }
};

//renommer fichier

export const renameFichier = async (req, res) => {
  const { fichier_id } = req.params;
  const { nouveauNom } = req.body;

  if (!nouveauNom) {
    return res.status(400).json({ error: "Le nouveau nom est requis" });
  }

  try {
    // Mise à jour du champ "nom" dans la base
    const result = await pool.query(
      'UPDATE fichiers SET nom = $1 WHERE fichier_id = $2 RETURNING *',
      [nouveauNom, fichier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }

    res.status(200).json({ message: "Nom du fichier mis à jour", fichier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors du renommage" });
  }
};

//get fichier

export const getFichierById = async (req, res) => {
  const {fichier_id } = req.params;

  if (!fichier_id) return res.status(400).json({ error: "ID du fichier requis" });

  try {
    const query = 'SELECT * FROM fichiers WHERE fichier_id = $1';
    const result = await pool.query(query, [fichier_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Fichier introuvable" });
    }

    res.status(200).json({ fichier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération du fichier" });
  }
};



// generer un lien signé

async function genererLienSigne(chemin) {

  const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';
  const key = chemin.replace(s3BaseUrl, '');
  const contentType = mime.lookup(chemin) || 'application/octet-stream';

  const command = new GetObjectCommand({
    Bucket: 'arkiva-storage',
    Key: key,
    ResponseContentType: contentType,
  });

  const url = await getSignedUrl(s3, command, { expiresIn: 3600 }); // 1h
  return url;
}



// afficher le fichier
export const displayFichier = async (req, res) => {
  const { fichier_id } = req.params;

  try {
    const { rows } = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Fichier introuvable' });

    const chemin = rows[0].chemin;

    const signedUrl = await genererLienSigne(chemin);
    res.redirect(signedUrl); // Redirection vers le lien signé

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du téléchargement' });
  }
};


//telecharger le fichier
export const telechargerFichier = async (req, res) => {
  const { fichier_id } = req.params;
  const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';

  try {
    const { rows } = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Fichier introuvable' });

    const chemin = rows[0].chemin;

    const key = chemin.replace(s3BaseUrl, '');
    const contentType = mime.lookup(chemin) || 'application/octet-stream';

    const command = new GetObjectCommand({
      Bucket: 'arkiva-storage',
      Key: key,
      ResponseContentType: contentType,
      ResponseContentDisposition: 'attachment', // <-- ceci force le téléchargement

    });

    const url = await getSignedUrl(s3, command, { expiresIn: 3600 }); // 1h
    console.log("URL signée:", url);

    // res.redirect(url); 

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du téléchargement' });
  }
};



export const getFichierCountByDossierId = async (req, res) => {
  const { dossier_id } = req.params;

  if (!dossier_id) return res.status(400).json({ error: "ID du dossier requis" });

  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM fichiers WHERE dossier_id = $1',
      [dossier_id]
    );

    res.status(200).json({ dossier_id, nombre_fichiers: parseInt(result.rows[0].count) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors du comptage des fichiers" });
  }
};


// export const partagerFichier = async (req, res) => {
//   const { fichier_id } = req.params;
//   const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';

//   try {
//     const { rows } = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
//     if (rows.length === 0) return res.status(404).json({ error: 'Fichier introuvable' });

//     const chemin = rows[0].chemin;
//     const key = chemin.replace(s3BaseUrl, '');
   
//     const contentType = mime.lookup(fichier.nom) || 'application/octet-stream';

//     const command = new GetObjectCommand({
//       Bucket: bucket,
//       Key: key,
//       ResponseContentType: contentType,
//       ResponseContentDisposition: 'inline', // 🔁 Affichage direct dans navigateur
//     });

//     const url = await getSignedUrl(s3, command, { expiresIn: 60 * 60 }); // 1h de validité

//     res.json({ lien: url }); // Tu renvoies le lien public temporaire

//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: "Erreur lors du partage du fichier" });
//   }
// };