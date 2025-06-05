import crypto from 'crypto';
import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import s3 from '../../config/aws.js';
import EncryptionKey from './encryptionKeyModel.js';

class EncryptionService {
    constructor() {
        // La clé maître doit faire 32 octets (256 bits) pour AES-256-GCM
        const masterKey = process.env.MASTER_KEY;
        if (!masterKey) {
            throw new Error('La clé maître (MASTER_KEY) doit être définie dans les variables d\'environnement');
        }
        
        // S'assure que la clé maître fait exactement 32 octets
        this.masterKey = crypto.createHash('sha256').update(masterKey).digest();
        this.bucketName = process.env.AWS_S3_BUCKET_NAME;
        
        if (!this.bucketName) {
            throw new Error('Le nom du bucket S3 (AWS_S3_BUCKET_NAME) doit être défini dans les variables d\'environnement');
        }
    }

    // Génère une nouvelle clé de chiffrement pour une entreprise
    async generateEncryptionKey(entrepriseId) {
        try {
            const key = crypto.randomBytes(32); // 256 bits
            const iv = crypto.randomBytes(16);
            
            // Chiffre la clé avec la clé maître
            const cipher = crypto.createCipheriv('aes-256-gcm', this.masterKey, iv);
            const encryptedKey = Buffer.concat([cipher.update(key), cipher.final()]);
            const authTag = cipher.getAuthTag();
            
            console.log('Génération de clé:', {
                entrepriseId,
                ivLength: iv.length,
                encryptedKeyLength: encryptedKey.length,
                authTagLength: authTag.length
            });

            // Stocke la clé chiffrée avec le tag d'authentification
            const keyData = {
                entreprise_id: entrepriseId,
                key_encrypted: encryptedKey.toString('base64'),
                iv: iv.toString('base64'),
                auth_tag: authTag.toString('base64')
            };

            console.log('Données de la clé à stocker:', {
                entreprise_id: keyData.entreprise_id,
                ivLength: keyData.iv.length,
                keyEncryptedLength: keyData.key_encrypted.length,
                authTagLength: keyData.auth_tag.length
            });

            const savedKey = await EncryptionKey.createKey(keyData);
            console.log('Clé sauvegardée:', savedKey);

            // Nettoie les anciennes clés
            await EncryptionKey.cleanupOldKeys(entrepriseId);

            return { key, iv };
        } catch (error) {
            console.error('Erreur lors de la génération de la clé:', error);
            throw error;
        }
    }

    // Récupère la clé de chiffrement d'une entreprise
    async getEncryptionKey(entrepriseId) {
        try {
            let keyRecord = await EncryptionKey.findByEntrepriseId(entrepriseId);
            console.log('Clé trouvée:', keyRecord);
            // Si la clé n'existe pas, on la génère
            if (!keyRecord) {
                console.log('Aucune clé trouvée pour l\'entreprise', entrepriseId, '- Génération d\'une nouvelle clé');
                const { key, iv } = await this.generateEncryptionKey(entrepriseId);
                keyRecord = await EncryptionKey.findByEntrepriseId(entrepriseId);
                console.log('Nouvelle clé générée:', keyRecord);
            }
            if (!keyRecord || !keyRecord.auth_tag) {
                throw new Error('Clé invalide ou incomplète');
            }
            // Déchiffre la clé avec la clé maître
            const decipher = crypto.createDecipheriv(
                'aes-256-gcm',
                this.masterKey,
                Buffer.from(keyRecord.iv, 'base64')
            );
            
            // Définit le tag d'authentification
            decipher.setAuthTag(Buffer.from(keyRecord.auth_tag, 'base64'));
            
            const decryptedKey = Buffer.concat([
                decipher.update(Buffer.from(keyRecord.key_encrypted, 'base64')),
                decipher.final()
            ]);

            return {
                key: decryptedKey,
                iv: Buffer.from(keyRecord.iv, 'base64')
            };
        } catch (error) {
            console.error('Erreur lors de la récupération de la clé:', error);
            throw error;
        }
    }

    // Chiffre un fichier et retourne le fichier chiffré
    async encryptFile(fileBuffer, originalFileName, entrepriseId) {
        try {
            const { key, iv } = await this.getEncryptionKey(entrepriseId);
        
            const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
            const encryptedContent = Buffer.concat([cipher.update(fileBuffer), cipher.final()]);
            const authTag = cipher.getAuthTag();
            
            // Créer un fichier chiffré qui contient les métadonnées et le contenu
            const encryptedFile = {
                content: encryptedContent,
                metadata: {
                    originalFileName,
                    iv: iv.toString('base64'),
                    authTag: authTag.toString('base64'),
                    entrepriseId
                }
            };
            
            return encryptedFile;
        } catch (error) {
            console.error('Erreur lors du chiffrement:', error);
            throw error;
        }
    }

    // Déchiffre un fichier depuis un buffer
    async decryptFile(encryptedFile, entrepriseId) {
        try {
            console.log('Début du processus de déchiffrement:', { entrepriseId });
            
            const { key } = await this.getEncryptionKey(entrepriseId);
            console.log('Clé de déchiffrement récupérée:', {
                keyLength: key.length
            });
            
            const decipher = crypto.createDecipheriv(
                'aes-256-gcm', 
                key, 
                Buffer.from(encryptedFile.metadata.iv, 'base64')
            );
            
            decipher.setAuthTag(Buffer.from(encryptedFile.metadata.authTag, 'base64'));
            
            const decryptedContent = Buffer.concat([
                decipher.update(encryptedFile.content),
                decipher.final()
            ]);
            
            console.log('Contenu déchiffré:', {
                decryptedLength: decryptedContent.length
            });
            
            return {
                content: decryptedContent,
                originalFileName: encryptedFile.metadata.originalFileName
            };
        } catch (error) {
            console.error('Erreur détaillée dans decryptFile:', {
                message: error.message,
                stack: error.stack,
                entrepriseId
            });
            throw error;
        }
    }
}

export default new EncryptionService(); 