import pool from '../../config/database.js';
import { logAction, ACTIONS, TARGET_TYPES } from '../audit/auditService.js';
import backupService from '../backup/backupService.js';
//import "./armoireModels.js";
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
  WHERE entreprise_id = $1 AND is_deleted = false
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
        // Récupérer l'ancien sous-titre avant modification
        const oldArmoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [armoire_id]);
        if (oldArmoireResult.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }
        const oldArmoire = oldArmoireResult.rows[0];
        const oldSousTitre = oldArmoire.sous_titre || '';

        // 📝 CRÉER UNE VERSION AUTOMATIQUE AVANT RENOMMAGE
        try {
            console.log(`🔄 [Auto-Version] Création de version automatique pour armoire ${armoire_id} avant renommage`);
            
            const versionData = {
                cible_id: armoire_id,
                type: 'armoire',
                version_number: 'auto',
                description: `Renommage: "${oldSousTitre}" → "${sous_titre}"`,
                metadata: {
                    old_sous_titre: oldSousTitre,
                    new_sous_titre: sous_titre,
                    reason: 'rename',
                    type: 'armoire'
                },
                entreprise_id: oldArmoire.entreprise_id
            };

            // Importer le service de versions
            const versionService = await import('../versions/versionService.js');
            
            // Créer la version de manière asynchrone
            versionService.default.createVersion(versionData, req.user?.user_id)
                .then(() => {
                    console.log(`✅ [Auto-Version] Version automatique créée pour armoire ${armoire_id}`);
                })
                .catch((versionError) => {
                    console.error(`❌ [Auto-Version] Erreur lors de la création de version:`, versionError);
                });

        } catch (versionError) {
            console.error(`❌ [Auto-Version] Erreur lors de la préparation de la version:`, versionError);
            // Continuer avec le renommage même si la version échoue
        }

        const update = await pool.query(
            'UPDATE armoires SET sous_titre = $1 WHERE armoire_id = $2 RETURNING *',
            [sous_titre, armoire_id]
        );

        if (update.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }

        // Log humain avec information de version
        const armoire = update.rows[0];
        const user = req.user;
        const now = new Date();
        const message = `L'utilisateur ${user.username} a renommé l'armoire "${armoire.nom}" (sous-titre: "${oldSousTitre}" → "${armoire.sous_titre}") le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une version automatique a été créée.`;
        await logAction(
            user.user_id,
            ACTIONS.UPDATE,
            TARGET_TYPES.FOLDER,
            armoire_id,
            {
                message,
                armoire_id,
                old_sous_titre: oldSousTitre,
                new_sous_titre: armoire.sous_titre,
                auto_version_created: true
            }
        );

        res.status(200).json({ 
            message: 'Sous-titre mis à jour', 
            armoire: update.rows[0],
            version_created: true
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la mise à jour de l\'armoire' });
    }
};


export const DeleteArmoire = async (req, res) => {
    const { armoire_id } = req.params;

    try {
        // Récupérer les infos de l'armoire avant suppression
        const armoireResult = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [armoire_id]);
        if (armoireResult.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }
        const armoire = armoireResult.rows[0];

        // 🗂️ CRÉER UNE SAUVEGARDE AUTOMATIQUE AVANT SUPPRESSION
        try {
            console.log(`🔄 [Auto-Backup] Création de sauvegarde automatique pour armoire ${armoire_id} avant suppression`);
            
            const backupData = {
                type: 'armoire',
                cible_id: armoire_id,
                entreprise_id: armoire.entreprise_id,
                mode: 'automatic',
                reason: 'deletion'
            };

            // Créer la sauvegarde de manière asynchrone
            backupService.createBackup(backupData, req.user?.user_id)
                .then(() => {
                    console.log(`✅ [Auto-Backup] Sauvegarde automatique créée pour armoire ${armoire_id}`);
                })
                .catch((backupError) => {
                    console.error(`❌ [Auto-Backup] Erreur lors de la sauvegarde automatique:`, backupError);
                });

        } catch (backupError) {
            console.error(`❌ [Auto-Backup] Erreur lors de la préparation de la sauvegarde:`, backupError);
            // Continuer avec la suppression même si la sauvegarde échoue
        }

        const deletion = await pool.query('UPDATE armoires SET is_deleted = true WHERE armoire_id = $1 RETURNING *', [armoire_id]);

        if (deletion.rowCount === 0) {
            return res.status(404).json({ error: 'Armoire non trouvée' });
        }

        // Log humain avec information de sauvegarde
        const user = req.user;
        const now = new Date();
        const message = `L'utilisateur ${user.username} a supprimé l'armoire "${armoire.nom}" le ${now.toLocaleDateString()} à ${now.toLocaleTimeString()}. Une sauvegarde automatique a été créée.`;
        await logAction(
            user.user_id,
            ACTIONS.DELETE,
            TARGET_TYPES.FOLDER,
            armoire_id,
            {
                message,
                armoire_id,
                auto_backup_created: true
            }
        );

        res.status(200).json({ 
            message: 'Armoire supprimée avec succès', 
            armoire: deletion.rows[0],
            backup_created: true
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la suppression de l\'armoire' });
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
