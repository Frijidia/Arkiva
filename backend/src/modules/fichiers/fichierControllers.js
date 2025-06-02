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

export async function getSignedUrlForFile(req, res) {
  const { fichier_id } = req.params;

  try {
    const result = await pool.query('SELECT chemin FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Fichier non trouvé' });
    }

    const chemin = result.rows[0].chemin;
    const url = await genererLienSigne(chemin);


    res.json({ url });
  } catch (error) {
    console.error('Erreur génération lien signé:', error);
    res.status(500).json({ error: 'Erreur lors de la génération du lien signé' });
  }
}