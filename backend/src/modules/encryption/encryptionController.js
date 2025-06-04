import encryptionService from './encryptionService.js';
import multer from 'multer';
import { Readable } from 'stream';

// Configuration de multer pour le stockage en mémoire
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 50 * 1024 * 1024 // Limite à 50MB
    }
});

class EncryptionController {
    // Middleware pour configurer multer
    static uploadMiddleware() {
        return upload.single('file');
    }

    // Chiffre un fichier
    static async encryptFile(req, res) {
        try {
            if (!req.file) {
                return res.status(400).json({ error: 'Aucun fichier n\'a été uploadé' });
            }

            const { entrepriseId } = req.params;
            const { s3Key, originalFileName } = await encryptionService.encryptFile(
                req.file.buffer,
                req.file.originalname,
                entrepriseId
            );

            res.json({
                message: 'Fichier chiffré avec succès',
                entrepriseId,
                s3Key,
                originalFileName
            });
        } catch (error) {
            console.error('Erreur lors du chiffrement:', error);
            res.status(500).json({
                error: 'Erreur lors du chiffrement du fichier',
                details: error.message
            });
        }
    }

    // Déchiffre un fichier
    static async decryptFile(req, res) {
        try {
            const { entrepriseId, s3Key } = req.params;
            console.log('Début du déchiffrement - Paramètres:', { entrepriseId, s3Key });

            const { content, originalFileName, contentType } = await encryptionService.decryptFile(s3Key, entrepriseId);
            console.log('Fichier déchiffré avec succès:', { 
                originalFileName, 
                contentType,
                contentLength: content.length 
            });

            // Vérifie que le contenu n'est pas vide
            if (!content || content.length === 0) {
                throw new Error('Le contenu déchiffré est vide');
            }

            res.setHeader('Content-Disposition', `attachment; filename="${originalFileName}"`);
            res.setHeader('Content-Type', contentType);
            res.setHeader('Content-Length', content.length);
            res.send(content);
        } catch (error) {
            console.error('Erreur détaillée lors du déchiffrement:', {
                message: error.message,
                stack: error.stack,
                params: req.params
            });
            
            res.status(500).json({
                error: 'Erreur lors du déchiffrement du fichier',
                details: error.message,
                code: error.code || 'UNKNOWN_ERROR'
            });
        }
    }

    // Génère une clé de chiffrement pour une entreprise
    static async generateKey(req, res) {
        try {
            const { entrepriseId } = req.params;
            const { key, iv } = await encryptionService.generateEncryptionKey(entrepriseId);
            
            res.json({
                message: 'Clé de chiffrement générée avec succès',
                entrepriseId,
                key: key.toString('base64'),
                iv: iv.toString('base64')
            });
        } catch (error) {
            console.error('Erreur lors de la génération de la clé:', error);
            res.status(500).json({
                error: 'Erreur lors de la génération de la clé',
                details: error.message
            });
        }
    }
}

export default EncryptionController; 