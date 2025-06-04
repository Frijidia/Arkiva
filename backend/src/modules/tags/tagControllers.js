import pool from '../../config/database.js';
import nlp from 'compromise';
import "./tagModels.js";
/**
 * 1. Créer un nouveau tag
 */

export async function createTag(req, res) {
    const { name, color, description } = req.body;

    try {
        const result = await pool.query(
            'INSERT INTO tags (name, color, description) VALUES ($1, $2, $3) RETURNING *',
            [name, color, description || '']
        );
        res.status(201).json({
            message: 'Tag créé avec succès',
            tag: result.rows[0],
        });
    } catch (error) {
        console.error('Erreur lors de la création du tag:', error.message);
        res.status(500).json({
            error: 'Une erreur est survenue lors de la création du tag',
        });
    }
}

/**
 * 2. Récupérer tous les tags
 */

export async function getAllTags(req, res) {
    try {
        const result = await pool.query('SELECT * FROM tags ORDER BY name');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des tags:', error);
        res.status(500).json({ error: 'Erreur serveur lors de la récupération des tags' });
    }
}


/**
 * 3. Supprimer un tag
 */

export async function deleteTag(req, res) {
    const { tag_id } = req.params;

    try {
        const result = await pool.query(
            'DELETE FROM tags WHERE tag_id = $1 RETURNING *',
            [tag_id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Tag non trouvé' });
        }

        res.status(200).json({ success: true, message: 'Tag supprimé avec succès' });
    } catch (error) {
        console.error('Erreur lors de la suppression du tag:', error.message);
        res.status(500).json({ error: 'Erreur interne lors de la suppression du tag' });
    }
}


/**
 * 4. Renommer un tag
 */

export async function renameTag(req, res) {
    const { tag_id } = req.params;
    const { newName } = req.body;

    try {
        const result = await pool.query(
            'UPDATE tags SET name = $1 WHERE tag_id = $2 RETURNING *',
            [newName, tag_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Tag non trouvé' });
        }

        res.status(200).json({
            message: 'Nom du tag mis à jour avec succès',
            tag: result.rows[0],
        });
    } catch (error) {
        console.error('Erreur lors du renommage du tag:', error.message);
        res.status(500).json({ error: 'Erreur interne lors du renommage du tag' });
    }
}

/**
 * 4. Ajouter un tag a un fichier
 */

export async function addTagToFile(req, res) {
    const { fichier_id, nom_tag } = req.body;

    if (!fichier_id || !nom_tag) {
        return res.status(400).json({ error: 'fichier_id et nom_tag sont obligatoires' });
    }

    try {
        // Chercher si le tag existe
        let result = await pool.query('SELECT tag_id FROM tags WHERE nom = $1', [nom_tag]);

        let tag_id;

        // S'il n'existe pas, on le crée
        if (result.rows.length === 0) {
            result = await pool.query('INSERT INTO tags (nom) VALUES ($1) RETURNING tag_id', [nom_tag]);
            tag_id = result.rows[0].tag_id;
        } else {
            tag_id = result.rows[0].tag_id;
        }

        // Vérifier si déjà associé
        result = await pool.query(
            'SELECT * FROM fichiers_tags WHERE fichier_id = $1 AND tag_id = $2',
            [fichier_id, tag_id]
        );

        if (result.rows.length > 0) {
            return res.status(200).json({ message: 'Le tag est déjà associé à ce fichier.' });
        }

        // Associer le tag au fichier
        result = await pool.query(
            'INSERT INTO fichiers_tags (fichier_id, tag_id) VALUES ($1, $2) RETURNING *',
            [fichier_id, tag_id]
        );

        res.status(201).json({
            message: 'Tag associé au fichier avec succès',
            association: result.rows[0]
        });

    } catch (error) {
        console.error('Erreur lors de l\'association tag-fichier :', error);
        res.status(500).json({
            error: 'Erreur serveur lors de l\'association tag-fichier',
            details: error.message
        });
    }
}


/**
 * 4. enlever un tag a un fichier
 */

export async function removeTagFromFile(req, res) {
    const { fichier_id, tag_id } = req.body;

    try {
        const query = 'DELETE FROM fichier_tags WHERE fichier_id = $1 AND tag_id = $2 RETURNING *';
        const result = await pool.query(query, [fichier_id, tag_id]);

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Association non trouvée' });
        }

        res.json({ message: 'Association tag-fichier supprimée avec succès' });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'association :', error);
        res.status(500).json({ error: 'Erreur serveur lors de la suppression de l\'association' });
    }
}


/**
 * 4. recuperer les fichiers par tag
 */

export async function getFilesByTag(req, res) {
    const { tag_id } = req.params;

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
 * 5. proposer des tags en fontion du contenu ocr
 */


export function extractKeywordsFromText(text, maxKeywords = 10) {
    const doc = nlp(text);

    const nouns = doc.nouns().out('array');
    const frequency = {};

    nouns.forEach(word => {
        const lower = word.toLowerCase();
        if (!frequency[lower]) frequency[lower] = 0;
        frequency[lower]++;
    });

    // Trier par fréquence décroissante
    const sorted = Object.entries(frequency)
        .sort((a, b) => b[1] - a[1])
        .slice(0, maxKeywords)
        .map(([word]) => word);

    return sorted;
}

/**
 * 6. recuperer les tags existant et ceux frequament utiliset
 */
export const getTagSuggestions = async (req, res) => {
    const { mode = 'top', limit = 10 } = req.query;

    try {
        if (mode === 'top') {
            const result = await pool.query(`
        SELECT tags.nom
        FROM fichier_tags
        JOIN tags ON tags.tag_id = fichier_tags.tag_id
        GROUP BY tags.nom
        ORDER BY COUNT(*) DESC
        LIMIT $1
      `, [limit]);

            return res.status(200).json({ tags: result.rows.map(row => row.nom) });
        }

        if (mode === 'voir_plus') {
            const topResult = await pool.query(`
        SELECT tags.nom
        FROM fichier_tags
        JOIN tags ON tags.tag_id = fichier_tags.tag_id
        GROUP BY tags.nom
        ORDER BY COUNT(*) DESC
        LIMIT $1
      `, [limit]);

            const topTags = topResult.rows.map(row => row.nom);

            const placeholders = topTags.map((_, index) => `$${index + 1}`).join(', ');

            const othersResult = await pool.query(`
        SELECT tags.nom, COUNT(fichier_tags.fichier_id) AS count
        FROM tags
        LEFT JOIN fichier_tags ON tags.tag_id = fichier_tags.tag_id
        WHERE tags.nom NOT IN (${placeholders})
        GROUP BY tags.nom
        ORDER BY count DESC
      `, topTags);

            return res.status(200).json({ tags: othersResult.rows.map(row => row.nom) });
        }

        return res.status(400).json({ error: 'Mode invalide. Utilise "top" ou "voir_plus".' });

    } catch (error) {
        console.error('Erreur lors de la suggestion de tags :', error);
        res.status(500).json({ error: 'Erreur serveur.' });
    }
};
