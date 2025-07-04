//import "./fichierModels.js";
import pool from '../../config/database.js';
import s3 from '../../config/aws.js';
import { GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import mime from "mime-types";
import encryptionService from '../encryption/encryptionService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';

// import fs from 'fs/promises';


// GET fichiers par dossier_id
export const getFichiersByDossierId = async (req, res) => {
  const { dossier_id } = req.params;

  if (!dossier_id) {
    return res.status(400).json({ error: "ID du dossier requis" });
  }

  try {
    const result = await pool.query(
      `SELECT f.*, 
        COALESCE(
          ARRAY_AGG(
            DISTINCT jsonb_build_object('name', t.name, 'color', t.color)
          ) FILTER (WHERE t.tag_id IS NOT NULL), 
          '{}'
        ) AS tags
      FROM fichiers f
      LEFT JOIN fichier_tags ft ON ft.fichier_id = f.fichier_id
      LEFT JOIN tags t ON t.tag_id = ft.tag_id
      WHERE f.dossier_id = $1
      GROUP BY f.fichier_id
      ORDER BY f.fichier_id DESC`,
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
    // Récupérer toutes les infos nécessaires pour le log
    const fichierResult = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (fichierResult.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }
    const fichier = fichierResult.rows[0];
    const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [fichier.dossier_id]);
    const dossier = dossierResult.rows[0] || { nom: '?' };
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
    const casier = casierResult.rows[0] || { nom: '?' };
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };

    const filePath = fichier.chemin;
    const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';
    const key = filePath.replace(s3BaseUrl, '');

    // Supprimer le fichier physique de S3
    await s3.send(new DeleteObjectCommand({
      Bucket: 'arkiva-storage',
      Key: key,
    }));

    // Supprimer de la base
    await pool.query('DELETE FROM fichiers WHERE fichier_id = $1', [fichier_id]);

    // Log humain
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a supprimé le fichier "${fichier.originalfilename || fichier.nom}" du casier "${casier.nom}" de l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}.`;
    await logAction(
      user.user_id,
      ACTIONS.DELETE,
      TARGET_TYPES.FILE,
      fichier_id,
      {
        message,
        fichier_id,
        dossier_id: dossier.dossier_id,
        casier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id
      }
    );

    res.status(200).json({ message: "Fichier supprimé avec succès" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la suppression du fichier" });
  }
};

//renommer fichier

export const renameFichier = async (req, res) => {
  const { fichier_id } = req.params;
  const { nouveauoriginalfilename } = req.body;

  if (!nouveauoriginalfilename) {
    return res.status(400).json({ error: "Le nouveau nom est requis" });
  }

  try {
    // Mise à jour du champ "nom" dans la base
    const result = await pool.query(
      'UPDATE fichiers SET originalfilename = $1 WHERE fichier_id = $2 RETURNING *',
      [nouveauoriginalfilename, fichier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }

    // Log humain
    const fichier = result.rows[0];
    const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [fichier.dossier_id]);
    const dossier = dossierResult.rows[0] || { nom: '?' };
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
    const casier = casierResult.rows[0] || { nom: '?' };
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a modifié le fichier "${fichier.originalfilename}" du dossier "${dossier.nom}", casier "${casier.nom}", armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}.`;
    await logAction(
      user.user_id,
      ACTIONS.UPDATE,
      TARGET_TYPES.FILE,
      fichier_id,
      {
        message,
        fichier_id,
        dossier_id: dossier.dossier_id,
        casier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id
      }
    );

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

// async function genererLienSigne(chemin) {

//   const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';
//   const key = chemin.replace(s3BaseUrl, '');
//   const contentType = mime.lookup(chemin) || 'application/octet-stream';

//   const command = new GetObjectCommand({
//     Bucket: 'arkiva-storage',
//     Key: key,
//     ResponseContentType: contentType,
//   });

//   const url = await getSignedUrl(s3, command, { expiresIn: 3600 }); // 1h
//   return url;
// }



//test

export async function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("error", reject);
    stream.on("end", () => resolve(Buffer.concat(chunks)));
  });
}


export default async function downloadFileBufferFromS3(key) {
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: key,
  });
  
  const response = await s3.send(command);

  // Convertir le ReadableStream en Buffer
  const buffer = await streamToBuffer(response.Body);
  return buffer;
}



// afficher le fichier

export const displayFichier = async (req, res) => {
  const { fichier_id, entreprise_id } = req.params;

  try {
    const { rows } = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Fichier introuvable' });

    const fichier = rows[0];
    const chemin = fichier.chemin;
    const s3BaseUrl = 'https://arkiva-storage.s3.amazonaws.com/';
    const key = chemin.replace(s3BaseUrl, '');

    // Étape 1 : Télécharger le fichier chiffré depuis S3
    const encryptedBuffer = await downloadFileBufferFromS3(key);

    // Étape 2 : Déchiffrer le buffer (le JSON est parsé dans decryptFile)
    const { content: decryptedBuffer, originalFileName } = await encryptionService.decryptFile(encryptedBuffer, entreprise_id);

    // Étape 3 : Détecter le bon type MIME
    const mimeType = mime.lookup(originalFileName) || 'application/octet-stream';
    let Name = originalFileName
    console.log(originalFileName)

    // Étape 4 : Répondre avec le fichier déchiffré
    res.setHeader('Content-Disposition', `inline; filename="${Name}"`);
    res.setHeader('Content-Type', mimeType);
    res.send(decryptedBuffer);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'affichage du fichier' });
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

