import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import s3 from '../config/aws.js';

const bucketName = process.env.AWS_S3_BUCKET_NAME;

class AwsStorageService {
    constructor() {
        if (!bucketName) {
            throw new Error('Le nom du bucket S3 (AWS_S3_BUCKET_NAME) doit être défini dans les variables d\'environnement');
        }
    }

    // Upload d'un fichier de sauvegarde vers S3
    async uploadBackup(fileBuffer, fileName) {
        try {
            const fileKey = `uploads/backups/${fileName}`;
            
            const command = new PutObjectCommand({
                Bucket: bucketName,
                Key: fileKey,
                Body: fileBuffer,
                ContentType: 'application/zip',
                Metadata: {
                    'upload-date': new Date().toISOString(),
                    'file-type': 'backup'
                }
            });

            await s3.send(command);

            return {
                location: `https://${bucketName}.s3.amazonaws.com/${fileKey}`,
                key: fileKey,
                size: fileBuffer.length,
                fileName: fileName
            };
        } catch (error) {
            console.error('Erreur lors de l\'upload de la sauvegarde vers S3:', error);
            throw error;
        }
    }

    // Upload d'une version vers S3
    async uploadVersion(fileBuffer, versionId, cibleId, type) {
        try {
            const fileKey = `uploads/versions/${cibleId}/${versionId}_content`;
            
            const command = new PutObjectCommand({
                Bucket: bucketName,
                Key: fileKey,
                Body: fileBuffer,
                ContentType: 'application/octet-stream',
                Metadata: {
                    'version-id': versionId,
                    'cible-id': cibleId.toString(),
                    'type': type,
                    'upload-date': new Date().toISOString(),
                    'file-type': 'version'
                }
            });

            await s3.send(command);

            return {
                location: `https://${bucketName}.s3.amazonaws.com/${fileKey}`,
                key: fileKey,
                size: fileBuffer.length,
                versionId: versionId
            };
        } catch (error) {
            console.error('Erreur lors de l\'upload de la version vers S3:', error);
            throw error;
        }
    }

    // Télécharger un fichier de sauvegarde depuis S3
    async downloadBackup(fileKey) {
        try {
            const command = new GetObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            });

            const response = await s3.send(command);
            const chunks = [];
            
            for await (const chunk of response.Body) {
                chunks.push(chunk);
            }
            
            return Buffer.concat(chunks);
        } catch (error) {
            console.error('Erreur lors du téléchargement de la sauvegarde depuis S3:', error);
            throw error;
        }
    }

    // Télécharger une version depuis S3
    async downloadVersion(fileKey) {
        try {
            const command = new GetObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            });

            const response = await s3.send(command);
            const chunks = [];
            
            for await (const chunk of response.Body) {
                chunks.push(chunk);
            }
            
            return Buffer.concat(chunks);
        } catch (error) {
            console.error('Erreur lors du téléchargement de la version depuis S3:', error);
            throw error;
        }
    }

    // Supprimer un fichier de sauvegarde de S3
    async deleteBackup(fileKey) {
        try {
            const command = new DeleteObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            });

            await s3.send(command);
            return true;
        } catch (error) {
            console.error('Erreur lors de la suppression de la sauvegarde de S3:', error);
            throw error;
        }
    }

    // Supprimer une version de S3
    async deleteVersion(fileKey) {
        try {
            const command = new DeleteObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            });

            await s3.send(command);
            return true;
        } catch (error) {
            console.error('Erreur lors de la suppression de la version de S3:', error);
            throw error;
        }
    }

    // Générer une URL signée pour télécharger un fichier
    async getSignedDownloadUrl(fileKey, expiresIn = 3600) {
        try {
            const command = new GetObjectCommand({
                Bucket: bucketName,
                Key: fileKey
            });

            const signedUrl = await getSignedUrl(s3, command, { expiresIn });
            return signedUrl;
        } catch (error) {
            console.error('Erreur lors de la génération de l\'URL signée:', error);
            throw error;
        }
    }

    // Lister les fichiers dans un dossier S3
    async listFiles(prefix) {
        try {
            const { ListObjectsV2Command } = await import('@aws-sdk/client-s3');
            const command = new ListObjectsV2Command({
                Bucket: bucketName,
                Prefix: prefix
            });

            const response = await s3.send(command);
            return response.Contents || [];
        } catch (error) {
            console.error('Erreur lors de la liste des fichiers S3:', error);
            throw error;
        }
    }
}

export default new AwsStorageService(); 