import pool from '../../config/database.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';
import backupService from '../backup/backupService.js';
//import "./dosierModels.js";


export const CreateDossier = async (req, res) => {
  const { cassier_id, nom, user_id } = req.body;

  if (!cassier_id || !nom) {
    return res.status(400).json({ error: 'cassier_id et nom sont requis' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO dossiers (cassier_id, nom, description, user_id) VALUES ($1, $2, $3, $4) RETURNING *',
      [cassier_id, nom, " ", user_id]
    );

    res.status(201).json({ message: 'Dossier créé', dossier: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur lors de la création du dossier' });
  }
};


export const GetDossiersByCasier = async (req, res) => {
  const { cassier_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM dossiers WHERE cassier_id = $1 ORDER BY dossier_id ASC',
      [cassier_id]
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
    // Récupérer les infos du dossier avant suppression
    const dossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [dossier_id]);
    if (dossierResult.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }
    const dossier = dossierResult.rows[0];

    // Récupérer les infos du casier et armoire
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
    const casier = casierResult.rows[0] || { nom: '?' };
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };

    // 🗂️ CRÉER UNE SAUVEGARDE AUTOMATIQUE AVANT SUPPRESSION
    try {
      console.log(`🔄 [Auto-Backup] Création de sauvegarde automatique pour dossier ${dossier_id} avant suppression`);
      
      const backupData = {
        type: 'dossier',
        cible_id: dossier_id,
        entreprise_id: armoire.entreprise_id,
        mode: 'automatic',
        reason: 'deletion'
      };

      // Créer la sauvegarde de manière asynchrone
      backupService.createBackup(backupData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Backup] Sauvegarde automatique créée pour dossier ${dossier_id}`);
        })
        .catch((backupError) => {
          console.error(`❌ [Auto-Backup] Erreur lors de la sauvegarde automatique:`, backupError);
        });

    } catch (backupError) {
      console.error(`❌ [Auto-Backup] Erreur lors de la préparation de la sauvegarde:`, backupError);
      // Continuer avec la suppression même si la sauvegarde échoue
    }

    const result = await pool.query(
      'DELETE FROM dossiers WHERE dossier_id = $1 RETURNING *',
      [dossier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }

    // Log humain avec information de sauvegarde
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a supprimé le dossier "${dossier.nom}" du casier "${casier.nom}" de l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une sauvegarde automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.DELETE,
      TARGET_TYPES.FOLDER,
      dossier_id,
      {
        message,
        dossier_id,
        casier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id,
        auto_backup_created: true
      }
    );

    res.status(200).json({ 
      message: 'Dossier supprimé avec succès', 
      dossier: result.rows[0],
      backup_created: true
    });
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
    // Récupérer l'ancien nom avant modification
    const oldDossierResult = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [dossier_id]);
    if (oldDossierResult.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }
    const oldDossier = oldDossierResult.rows[0];
    const oldName = oldDossier.nom;

    // 📝 CRÉER UNE VERSION AUTOMATIQUE AVANT RENOMMAGE
    try {
      console.log(`🔄 [Auto-Version] Création de version automatique pour dossier ${dossier_id} avant renommage`);
      
      const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [oldDossier.cassier_id]);
      const casier = casierResult.rows[0] || { nom: '?' };
      const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
      const armoire = armoireResult.rows[0] || { nom: '?' };

      const versionData = {
        cible_id: dossier_id,
        type: 'dossier',
        version_number: 'auto',
        description: `Renommage: "${oldName}" → "${nom}"`,
        metadata: {
          old_name: oldName,
          new_name: nom,
          reason: 'rename',
          type: 'dossier'
        },
        entreprise_id: armoire.entreprise_id
      };

      // Importer le service de versions
      const versionService = await import('../versions/versionService.js');
      
      // Créer la version de manière asynchrone
      versionService.default.createVersion(versionData, req.user?.user_id)
        .then(() => {
          console.log(`✅ [Auto-Version] Version automatique créée pour dossier ${dossier_id}`);
        })
        .catch((versionError) => {
          console.error(`❌ [Auto-Version] Erreur lors de la création de version:`, versionError);
        });

    } catch (versionError) {
      console.error(`❌ [Auto-Version] Erreur lors de la préparation de la version:`, versionError);
      // Continuer avec le renommage même si la version échoue
    }

    const result = await pool.query(
      'UPDATE dossiers SET nom = $1 WHERE dossier_id = $2 RETURNING *',
      [nom, dossier_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Dossier non trouvé' });
    }

    // Log humain avec information de version
    const dossier = result.rows[0];
    const casierResult = await pool.query('SELECT * FROM casiers WHERE cassier_id = $1', [dossier.cassier_id]);
    const casier = casierResult.rows[0] || { nom: '?' };
    const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [casier.armoire_id]);
    const armoire = armoireResult.rows[0] || { nom: '?' };
    const user = req.user;
    const now = new Date();
    const message = `L'utilisateur ${user.username} a renommé le dossier "${oldName}" en "${dossier.nom}" du casier "${casier.nom}", armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une version automatique a été créée.`;
    await logAction(
      user.user_id,
      ACTIONS.UPDATE,
      TARGET_TYPES.FOLDER,
      dossier_id,
      {
        message,
        dossier_id,
        casier_id: casier.cassier_id,
        armoire_id: armoire.armoire_id,
        old_name: oldName,
        new_name: dossier.nom,
        auto_version_created: true
      }
    );

    res.status(200).json({ 
      message: 'Nom du dossier mis à jour', 
      dossier: result.rows[0],
      version_created: true
    });
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
  const { cassier_id } = req.params;

  if (!cassier_id) return res.status(400).json({ error: "ID du casier requis" });

  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM dossiers WHERE cassier_id = $1',
      [cassier_id]
    );

    res.status(200).json({ cassier_id, nombre_dossiers: parseInt(result.rows[0].count) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors du comptage des dossiers" });
  }
};

// Déplacement d'un dossier vers un autre casier
export const deplacerDossier = async (req, res) => {
  const { id } = req.params; // ID du dossier
  const { nouveau_casier_id } = req.body;

  try {
    const result = await pool.query(
      `UPDATE dossiers SET casier_id = $1 WHERE dossier_id = $2 RETURNING *`,
      [nouveau_casier_id, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Dossier non trouvé" });
    }

    res.status(200).json({ message: "Dossier déplacé avec succès", dossier: result.rows[0] });
  } catch (err) {
    console.error("Erreur déplacement dossier :", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
};