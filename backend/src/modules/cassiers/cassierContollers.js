import pool from '../../config/database.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';
import backupService from '../backup/backupService.js';
//import "./cassierModels.js";



async function getArmoireUsedSpace(armoire_id) {
  const result = await pool.query(`
    SELECT COALESCE(SUM(fichiers.taille), 0) AS total_octets
    FROM fichiers
    JOIN dossiers ON fichiers.dossier_id = dossiers.dossier_id
    JOIN casiers ON dossiers.cassier_id = casiers.cassier_id
    WHERE casiers.armoire_id = $1
      AND fichiers.is_deleted = false
  `, [armoire_id]);

  return parseInt(result.rows[0].total_octets) || 0;
}


// création d’un casier
export const CreateCasier = async (req, res) => {
  const { armoire_id, user_id } = req.body;
  const sous_titre = "";

  if (!armoire_id || !user_id) {
    return res.status(400).json({ error: 'armoire_id et user_id requis' });
  }

  try {
    // 1. Récupérer la taille_max de l’armoire
    const armoireResult = await pool.query(
      'SELECT taille_max FROM armoires WHERE armoire_id = $1',
      [armoire_id]
    );

    if (armoireResult.rowCount === 0) {
      return res.status(404).json({ error: 'Armoire non trouvée' });
    }

    // determiner si il reste de l'espace dans l'armoire
    const taille_max = parseInt(armoireResult.rows[0].taille_max);
    const totalUtilise = await getArmoireUsedSpace(armoire_id);
    const espaceRestant = taille_max - totalUtilise;

    if (espaceRestant <= 0) {
      return res.status(400).json({ error: "L'armoire a atteint sa capacité maximale de stockage." });
    }

    // 4. Récupérer tous les noms de casiers existants pour cette armoire
    const casiersResult = await pool.query(
      'SELECT nom FROM casiers WHERE armoire_id = $1',
      [armoire_id]
    );

    const nomsExistant = casiersResult.rows.map(c => parseInt(c.nom.replace('C', '')));

    // 5. Trouver un numéro libre pour le casier (optionnel, juste pour garder un nom unique)
    let numeroLibre = 1;
    while (nomsExistant.includes(numeroLibre)) {
      numeroLibre++;
    }

    const nomCasier = `C${numeroLibre}`;

    // 6. Insérer le casier
    const insert = await pool.query(
      'INSERT INTO casiers (armoire_id, nom, sous_titre, user_id) VALUES ($1, $2, $3, $4) RETURNING *',
      [armoire_id, nomCasier, sous_titre, user_id]
    );

    res.status(201).json({
      message: 'Casier créé',
      casier: insert.rows[0],
      espace_restants: espaceRestant // en octets
    });


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
      `SELECT * FROM casiers WHERE armoire_id = $1 AND is_deleted = false 
      ORDER BY CAST(regexp_replace(nom, \'\\D\', \'\', \'g\') AS INTEGER)`,
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
    // Récupérer l'ancien sous-titre avant modification
    const oldCasierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [cassier_id]);
    if (oldCasierResult.rowCount === 0) {
      return res.status(404).json({ error: 'Casier non trouvé' });
    }
    const oldCasier = oldCasierResult.rows[0];
    const oldSousTitre = oldCasier.sous_titre || '';

    // 📝 CRÉER UNE VERSION AUTOMATIQUE AVANT RENOMMAGE
    try {
      console.log(`🔄 [Auto-Version] Création de version automatique pour casier ${cassier_id} avant renommage`);
      
      const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [oldCasier.armoire_id]);
      const armoire = armoireResult.rows[0] || { nom: '?' };

      const versionData = {
        cible_id: cassier_id,
        type: 'casier',
        version_number: 'auto',
        description: `Renommage: "${oldSousTitre}" → "${sous_titre}"`,
        metadata: {
          old_sous_titre: oldSousTitre,
          new_sous_titre: sous_titre,
          reason: 'rename',
          type: 'casier'
        },
        entreprise_id: armoire.entreprise_id
      };

      // Importer le service de versions
      const versionService = await import('../versions/versionService.js');
      
      // Créer la version de manière asynchrone
      versionService.default.createVersion(versionData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Version] Version automatique créée pour casier ${cassier_id}`);
        })
        .catch((versionError) => {
          console.error(`❌ [Auto-Version] Erreur lors de la création de version:`, versionError);
        });

    } catch (versionError) {
      console.error(`❌ [Auto-Version] Erreur lors de la préparation de la version:`, versionError);
      // Continuer avec le renommage même si la version échoue
    }

    const update = await pool.query(
      'UPDATE casiers SET sous_titre = $1 WHERE cassier_id = $2 RETURNING *',
      [sous_titre, cassier_id]
    );

    if (update.rowCount === 0) {
      return res.status(404).json({ error: 'Casier non trouvé' });
    }

    // Log humain avec information de version
    const casier = update.rows[0];
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a renommé le casier "${casier.nom}" (sous-titre: "${oldSousTitre}" → "${casier.sous_titre}") de l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une version automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.UPDATE,
      TARGET_TYPES.FOLDER,
      cassier_id,
      {
        message,
        cassier_id,
        armoire_id: armoire.armoire_id,
        old_sous_titre: oldSousTitre,
        new_sous_titre: casier.sous_titre,
        auto_version_created: true
      }
    );

    res.status(200).json({ 
      message: 'Sous-titre du casier mis à jour', 
      casier: update.rows[0],
      version_created: true
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du casier' });
  }
};


export const DeleteCasier = async (req, res) => {
  const { cassier_id } = req.params;

  try {
    // Récupérer les infos du casier avant suppression
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [cassier_id]);
    if (casierResult.rowCount === 0) {
      return res.status(404).json({ error: 'Casier non trouvé' });
    }
    const casier = casierResult.rows[0];

    // Récupérer les infos de l'armoire
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };

    // 🗂️ CRÉER UNE SAUVEGARDE AUTOMATIQUE AVANT SUPPRESSION
    try {
      console.log(`🔄 [Auto-Backup] Création de sauvegarde automatique pour casier ${cassier_id} avant suppression`);
      
      const backupData = {
        type: 'casier',
        cible_id: cassier_id,
        entreprise_id: armoire.entreprise_id,
        mode: 'automatic',
        reason: 'deletion'
      };

      // Créer la sauvegarde de manière asynchrone
      backupService.createBackup(backupData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Backup] Sauvegarde automatique créée pour casier ${cassier_id}`);
        })
        .catch((backupError) => {
          console.error(`❌ [Auto-Backup] Erreur lors de la sauvegarde automatique:`, backupError);
        });

    } catch (backupError) {
      console.error(`❌ [Auto-Backup] Erreur lors de la préparation de la sauvegarde:`, backupError);
      // Continuer avec la suppression même si la sauvegarde échoue
    }

    const deletion = await pool.query('UPDATE casiers SET is_deleted = true WHERE cassier_id = $1 RETURNING *', [cassier_id]);

    if (deletion.rowCount === 0) {
      return res.status(404).json({ error: 'Casier non trouvé' });
    }

    // Log humain avec information de sauvegarde
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a supprimé le casier "${casier.nom}" de l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une sauvegarde automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.DELETE,
      TARGET_TYPES.FOLDER,
      cassier_id,
      {
        message,
        cassier_id,
        armoire_id: armoire.armoire_id,
        auto_backup_created: true
      }
    );

    res.status(200).json({ 
      message: 'Casier supprimé avec succès', 
      casier: deletion.rows[0],
      backup_created: true
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression du casier' });
  }
};


export const getCasierById = async (req, res) => {
  const { cassier_id } = req.params;

  if (!cassier_id) return res.status(400).json({ error: "ID du casier requis" });

  try {
    const result = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [cassier_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Casier introuvable" });
    }

    res.status(200).json({ casier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération du casier" });
  }
};




// Déplacement d'un casier vers une autre armoire

export const deplacerCasier = async (req, res) => {
  const { id } = req.params; // ID du casier à déplacer
  const { nouvelle_armoire_id } = req.body;

  try {
    // 1. Calculer la taille totale des fichiers dans le casier (non supprimés)
    const fichiersSizeResult = await pool.query(`
      SELECT COALESCE(SUM(f.taille), 0) AS total_casier
      FROM fichiers f
      JOIN dossiers d ON f.dossier_id = d.dossier_id
      WHERE d.cassier_id = $1 AND f.is_deleted = false
    `, [id]);

    const tailleCasier = parseInt(fichiersSizeResult.rows[0].total_casier) || 0;

    // 2. Récupérer la taille_max de la nouvelle armoire
    const armoireResult = await pool.query(
      `SELECT taille_max FROM armoires WHERE armoire_id = $1`,
      [nouvelle_armoire_id]
    );

    if (armoireResult.rowCount === 0) {
      return res.status(404).json({ error: "Nouvelle armoire non trouvée" });
    }

    const tailleMax = parseInt(armoireResult.rows[0].taille_max);

    // 3. Calculer l'espace déjà utilisé dans la nouvelle armoire
    const espaceUtiliseResult = await pool.query(`
      SELECT COALESCE(SUM(f.taille), 0) AS total_utilise
      FROM fichiers f
      JOIN dossiers d ON f.dossier_id = d.dossier_id
      JOIN casiers c ON d.cassier_id = c.cassier_id
      WHERE c.armoire_id = $1 AND f.is_deleted = false
    `, [nouvelle_armoire_id]);

    const espaceUtilise = parseInt(espaceUtiliseResult.rows[0].total_utilise) || 0;
    const espaceRestant = tailleMax - espaceUtilise;

    // 4. Vérifier si l’espace est suffisant
    if (tailleCasier > espaceRestant) {
      return res.status(400).json({ error: "Pas assez d’espace dans la nouvelle armoire" });
    }

    // 5. Déplacement du casier
    const result = await pool.query(
      `UPDATE casiers SET armoire_id = $1 WHERE cassier_id = $2 RETURNING *`,
      [nouvelle_armoire_id, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Casier non trouvé" });
    }

    res.status(200).json({
      message: "Casier déplacé avec succès",
      casier: result.rows[0]
    });

  } catch (err) {
    console.error("Erreur déplacement casier :", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
};
