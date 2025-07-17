//import "./fichierModels.js";
import pool from '../../config/database.js';
import s3 from '../../config/aws.js';
import { GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import mime from "mime-types";
import encryptionService from '../encryption/encryptionService.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';
import backupService from '../backup/backupService.js';

// import fs from 'fs/promises';


// GET fichiers par dossier_id
export const getFichiersByDossierId = async (req, res) => {
  const { dossier_id } = req.params;

  if (!dossier_id) {
    return res.status(400).json({ error: "ID du dossier requis" });
  }

  try {
    // Récupérer les fichiers avec leurs tags
    const result = await pool.query(`
      SELECT 
        f.*,
        COALESCE(
          json_agg(
            json_build_object(
              'tag_id', t.tag_id,
              'name', t.name,
              'color', t.color,
              'description', t.description
            )
          ) FILTER (WHERE t.tag_id IS NOT NULL),
          '[]'::json
        ) as tags
      FROM fichiers f
      LEFT JOIN fichier_tags ft ON f.fichier_id = ft.fichier_id
      LEFT JOIN tags t ON ft.tag_id = t.tag_id
      WHERE f.dossier_id = $1 AND f.is_deleted = false
      GROUP BY f.fichier_id
      ORDER BY f.fichier_id DESC
    `, [dossier_id]);

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

    // 🗂️ CRÉER UNE SAUVEGARDE AUTOMATIQUE AVANT SUPPRESSION
    try {
      console.log(`🔄 [Auto-Backup] Création de sauvegarde automatique pour fichier ${fichier_id} avant suppression`);
      
      const backupData = {
        type: 'fichier',
        cible_id: fichier_id,
        entreprise_id: armoire.entreprise_id,
        mode: 'automatic',
        reason: 'deletion'
      };

      // Créer la sauvegarde de manière asynchrone (ne pas bloquer la suppression)
      backupService.createBackup(backupData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Backup] Sauvegarde automatique créée pour fichier ${fichier_id}`);
        })
        .catch((backupError) => {
          console.error(`❌ [Auto-Backup] Erreur lors de la sauvegarde automatique:`, backupError);
        });

    } catch (backupError) {
      console.error(`❌ [Auto-Backup] Erreur lors de la préparation de la sauvegarde:`, backupError);
      // Continuer avec la suppression même si la sauvegarde échoue
    }

    const filePath = fichier.chemin;
    const s3BaseUrl = `https://${process.env.AWS_S3_BUCKET_NAME}.s3.amazonaws.com/`;
    const key = filePath.replace(s3BaseUrl, '');

    // Supprimer le fichier physique de S3
    await s3.send(new DeleteObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET_NAME,
      Key: key,
    }));

    // Soft delete - marquer comme supprimé
    await pool.query('UPDATE fichiers SET is_deleted = true WHERE fichier_id = $1', [fichier_id]);

    // Log humain avec information de sauvegarde
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a supprimé le fichier "${fichier.originalfilename || fichier.nom}" du casier "${casier.nom}" de l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une sauvegarde automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.DELETE,
      TARGET_TYPES.FILE,
      fichier_id,
      {
        message,
        fichier_id,
        dossier_id: dossier.dossier_id,
        cassier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id,
        auto_backup_created: true
      }
    );

    res.status(200).json({ 
      message: "Fichier supprimé avec succès",
      backup_created: true
    });
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
    // Récupérer l'ancien nom avant modification
    const oldFichierResult = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (oldFichierResult.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }
    const oldFichier = oldFichierResult.rows[0];
    const oldName = oldFichier.originalfilename || oldFichier.nom;

    // 📝 CRÉER UNE VERSION AUTOMATIQUE AVANT RENOMMAGE
    try {
      console.log(`🔄 [Auto-Version] Création de version automatique pour fichier ${fichier_id} avant renommage`);
      
      const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [oldFichier.dossier_id]);
      const dossier = dossierResult.rows[0] || { nom: '?' };
      const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
      const casier = casierResult.rows[0] || { nom: '?' };
      const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
      const armoire = armoireResult.rows[0] || { nom: '?' };

      const versionData = {
        cible_id: fichier_id,
        type: 'fichier',
        version_number: 'auto',
        description: `Renommage: "${oldName}" → "${nouveauoriginalfilename}"`,
        metadata: {
          old_name: oldName,
          new_name: nouveauoriginalfilename,
          reason: 'rename',
          type: 'fichier'
        },
        entreprise_id: armoire.entreprise_id
      };

      // Importer le service de versions
      const versionService = await import('../versions/versionService.js');
      
      // Créer la version de manière asynchrone
      versionService.default.createVersion(versionData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Version] Version automatique créée pour fichier ${fichier_id}`);
        })
        .catch((versionError) => {
          console.error(`❌ [Auto-Version] Erreur lors de la création de version:`, versionError);
        });

    } catch (versionError) {
      console.error(`❌ [Auto-Version] Erreur lors de la préparation de la version:`, versionError);
      // Continuer avec le renommage même si la version échoue
    }

    // Mise à jour du champ "nom" dans la base
    const result = await pool.query(
      'UPDATE fichiers SET originalfilename = $1 WHERE fichier_id = $2 RETURNING *',
      [nouveauoriginalfilename, fichier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé" });
    }

    // Log humain avec information de version
    const fichier = result.rows[0];
    const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [fichier.dossier_id]);
    const dossier = dossierResult.rows[0] || { nom: '?' };
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
    const casier = casierResult.rows[0] || { nom: '?' };
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a renommé le fichier "${oldName}" en "${fichier.originalfilename}" du dossier "${dossier.nom}", casier "${casier.nom}", armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une version automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.UPDATE,
      TARGET_TYPES.FILE,
      fichier_id,
      {
        message,
        fichier_id,
        dossier_id: dossier.dossier_id,
        cassier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id,
        old_name: oldName,
        new_name: fichier.originalfilename,
        auto_version_created: true
      }
    );

    res.status(200).json({ 
      message: "Nom du fichier mis à jour", 
      fichier: result.rows[0],
      version_created: true
    });
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
  console.log('displayFichier params:', req.params);
  const { fichier_id, entreprise_id } = req.params;

  try {
    const { rows } = await pool.query('SELECT * FROM fichiers WHERE fichier_id = $1', [fichier_id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Fichier introuvable' });

    const fichier = rows[0];
    const chemin = fichier.chemin;
    let key = chemin;
    if (key.startsWith('http')) {
      key = key.replace(/^https?:\/\/[^/]+\//, '');
    }

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

// Déplacement d'un fichier vers un autre dossier
export const deplacerFichier = async (req, res) => {
  const { id } = req.params; // ID du fichier à déplacer
  const { nouveau_dossier_id } = req.body;

  try {
    // 1. Récupère les infos du fichier (notamment sa taille)
    const fichierResult = await pool.query(
      `SELECT taille FROM fichiers WHERE fichier_id = $1 AND is_deleted = false`,
      [id]
    );

    if (fichierResult.rowCount === 0) {
      return res.status(404).json({ error: "Fichier non trouvé ou supprimé" });
    }

    const tailleFichier = parseInt(fichierResult.rows[0].taille);

    // 2. Récupère le casier et l'armoire associés au nouveau dossier
    const dossierResult = await pool.query(
      `SELECT c.armoire_id FROM dossiers d
       JOIN casiers c ON d.cassier_id = c.cassier_id
       WHERE d.dossier_id = $1`,
      [nouveau_dossier_id]
    );

    if (dossierResult.rowCount === 0) {
      return res.status(404).json({ error: "Nouveau dossier non trouvé" });
    }

    const armoireId = dossierResult.rows[0].armoire_id;

    // 3. Récupère la taille maximale autorisée de l’armoire
    const armoireResult = await pool.query(
      `SELECT taille_max FROM armoires WHERE armoire_id = $1`,
      [armoireId]
    );

    const tailleMax = parseInt(armoireResult.rows[0].taille_max);

    // 4. Calcule l'espace actuellement utilisé dans l'armoire (sans les fichiers supprimés)
    const usedSpaceResult = await pool.query(`
      SELECT COALESCE(SUM(f.taille), 0) AS total
      FROM fichiers f
      JOIN dossiers d ON f.dossier_id = d.dossier_id
      JOIN casiers c ON d.cassier_id = c.cassier_id
      WHERE c.armoire_id = $1 AND f.is_deleted = false
    `, [armoireId]);

    const espaceUtilise = parseInt(usedSpaceResult.rows[0].total);

    // 5. Vérifie si l’armoire a encore de l’espace
    if (espaceUtilise + tailleFichier > tailleMax) {
      return res.status(400).json({ error: "Pas assez d’espace dans l’armoire cible" });
    }

    // 6. Déplace le fichier vers le nouveau dossier
    const updateResult = await pool.query(
      `UPDATE fichiers SET dossier_id = $1 WHERE fichier_id = $2 RETURNING *`,
      [nouveau_dossier_id, id]
    );

    res.status(200).json({ message: "Fichier déplacé avec succès", fichier: updateResult.rows[0] });

  } catch (err) {
    console.error("Erreur déplacement fichier :", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
};

