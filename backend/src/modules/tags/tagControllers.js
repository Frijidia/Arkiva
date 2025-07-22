import pool from '../../config/database.js';
import nlp from 'compromise';
//import "./tagModels.js";


/**
 * 1. Créer un nouveau tag
 */

export async function createTag(req, res) {
    console.log('Body reçu pour création de tag:', req.body);
    const { name, color, description, entreprise_id } = req.body;

    try {
        const result = await pool.query(
            'INSERT INTO tags (name, color, description, entreprise_id) VALUES ($1, $2, $3, $4) RETURNING *',
            [name, color, description || '', entreprise_id]
        );

        res.status(201).json({
            message: 'Tag créé avec succès',
            tag: result.rows[0],
        });
    } catch (error) {
        if (error.code === '23505') {
            // Violation de contrainte UNIQUE
            return res.status(400).json({
                error: 'Un tag avec ce nom existe déjà pour cette entreprise.',
            });
        }

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
    const { entreprise_id } = req.query;

    try {
        const result = await pool.query(
            'SELECT * FROM tags WHERE entreprise_id = $1 ORDER BY name',
            [entreprise_id]
        );
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
    const { entreprise_id } = req.body;

    try {
        const result = await pool.query(
            'DELETE FROM tags WHERE tag_id = $1 AND entreprise_id = $2 RETURNING *',
            [tag_id, entreprise_id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Tag non trouvé ou non autorisé' });
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
    const { fichier_id, nom_tag, entreprise_id } = req.body;

    if (!fichier_id || !nom_tag || !entreprise_id) {
        return res.status(400).json({ error: 'fichier_id, nom_tag et entreprise_id sont obligatoires' });
    }

    try {
        // Chercher si le tag existe pour cette entreprise
        let result = await pool.query(
            'SELECT tag_id FROM tags WHERE name = $1 AND entreprise_id = $2',
            [nom_tag, entreprise_id]
        );

        let tag_id;

        if (result.rows.length === 0) {
            const defaultColor = '#3498db';
            const defaultDescription = '';

            result = await pool.query(
                'INSERT INTO tags (name, color, description, entreprise_id) VALUES ($1, $2, $3, $4) RETURNING tag_id',
                [nom_tag, defaultColor, defaultDescription, entreprise_id]
            );

            tag_id = result.rows[0].tag_id;
        } else {
            tag_id = result.rows[0].tag_id;
        }

        // Vérifier si déjà associé
        result = await pool.query(
            'SELECT * FROM fichier_tags WHERE fichier_id = $1 AND tag_id = $2 AND entreprise_id =$3',
            [fichier_id, tag_id, entreprise_id]
        );

        if (result.rows.length > 0) {
            return res.status(200).json({ message: 'Le tag est déjà associé à ce fichier.' });
        }

        result = await pool.query(
            'INSERT INTO fichier_tags (fichier_id, tag_id, entreprise_id) VALUES ($1, $2, $3) RETURNING *',
            [fichier_id, tag_id, entreprise_id]
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
 * 5. proposer des tags en fontion du contenu ocr
 */


export function extractKeywordsFromText(text, maxKeywords = 4) {
    const stopWords = new Set([
        'il', 'elle', 'dans', 'le', 'la', 'les', 'de', 'des', 'un', 'une', 'et', 'à', 'en', 'du', 'au', 'aux', 'pour', 'par', 'sur', 'avec', 'ce', 'ces', 'qui', 'que', 'quoi', 'où', 'mais', 'ou', 'donc', 'or', 'ni', 'car'
    ]);

    const doc = nlp(text);
    const nouns = doc.nouns().out('array');
    const frequency = {};

    nouns.forEach(word => {
        const lower = word.toLowerCase();
        if (stopWords.has(lower)) return; // Ignore stop words
        if (lower.length < 4) return;    // Ignore mots trop courts

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

export const getSuggestedTagsByFileId = async (req, res) => {
    const { fichier_id } = req.body;

    if (!fichier_id) {
        return res.status(400).json({ error: 'Le paramètre fichier_id est requis.' });
    }

    try {
        const result = await pool.query(
            `SELECT * FROM fichiers WHERE fichier_id = $1`,
            [fichier_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Fichier non trouvé.' });
        }

        const text = result.rows[0].contenu_ocr;

        if (!text) {
            return res.status(404).json({ error: 'Texte OCR non disponible pour ce fichier.' });
        }

        // Extraire les tags du texte OCR
        const tags = extractKeywordsFromText(text, 5);

        return res.status(200).json({ tags });
    } catch (error) {
        console.error('Erreur extraction tags par fichier :', error);
        return res.status(500).json({ error: 'Erreur serveur.' });
    }
};



/**
 * 6. recuperer les tags frequament utiliser et suivi des autres tags
 */

export const getPopularTags = async (req, res) => {
    const { entreprise_id } = req.query;
    const limit = 10;

    try {
        const topResult = await pool.query(
            `
            SELECT tags.name, COUNT(fichier_tags.fichier_id)
            FROM fichier_tags
            JOIN tags ON tags.tag_id = fichier_tags.tag_id
            WHERE tags.entreprise_id = $1
            GROUP BY tags.name
            ORDER BY COUNT(fichier_tags.fichier_id) DESC
            LIMIT $2
            `,
            [entreprise_id, limit]
        );

        const topTags = topResult.rows.map(row => row.name);
        return res.status(200).json({ tags: topTags });

    } catch (error) {
        console.error('Erreur récupération tags populaires :', error);
        return res.status(500).json({ error: 'Erreur serveur.' });
    }
};


/**
 * . recuperer les tags par fichiers 
 */


export const getTagsForFile = async (req, res) => {
    const { fichier_id } = req.params;

    if (!fichier_id) {
        return res.status(400).json({ error: "L'identifiant du fichier est requis." });
    }

    try {
        const result = await pool.query(`
      SELECT tags.tag_id, tags.name
      FROM fichier_tags
      JOIN tags ON fichier_tags.tag_id = tags.tag_id
      WHERE fichier_tags.fichier_id = $1
    `, [fichier_id]);

        return res.status(200).json({ tags: result.rows });
    } catch (error) {
        console.error("Erreur lors de la récupération des tags :", error);
        return res.status(500).json({ error: "Erreur serveur lors de la récupération des tags." });
    }
};
