import multer from 'multer';
import { PutObjectCommand } from '@aws-sdk/client-s3';
import s3 from '../../config/aws.js';
import pool from '../../config/database.js';
import fs from 'fs';
import path from 'path';
import libre from 'libreoffice-convert';
import { promisify } from 'util';
import { extractSmartText } from '../ocr/ocrControllers.js';
import encryptionService from '../encryption/encryptionService.js';
import { GetObjectCommand } from "@aws-sdk/client-s3";



const convert = promisify(libre.convert);
const bucketName = process.env.AWS_S3_BUCKET_NAME;  // ton bucket S3


//verifier le type du fichier
const allowedExtensions = [
  '.pdf',
  '.doc',
  '.docx',
  '.txt',
  '.jpg',
  '.jpeg',
  '.png',
  '.bmp',
  '.tiff',
  '.webp'
];

function isAllowedExtension(filename) {
  const ext = path.extname(filename).toLowerCase();
  return allowedExtensions.includes(ext);
}

//fonction pour convertir en pdf

const convertToPdf = async (filePath) => {
  const fileExt = path.extname(filePath).toLowerCase();
  if (!['.doc', '.docx'].includes(fileExt)) return null;

  const file = fs.readFileSync(filePath);
  const outputPath = filePath.replace(fileExt, '.pdf');

  const pdfBuf = await convert(file, '.pdf', undefined);
  fs.writeFileSync(outputPath, pdfBuf);

  return outputPath;
};


//fonction pour le stockage local 
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads"),
  filename: (req, file, cb) => {
    const fileName = Date.now() + '-' + file.originalname;
    cb(null, fileName);
  },
});

export const upload = multer({ storage });



//fonction pour upload sur s3
export const uploadFileBufferToS3 = async (fileBuffer, originalName) => {
  const fileKey = 'uploads/' + Date.now() + '-' + originalName;

  const command = new PutObjectCommand({
    Bucket: bucketName,
    Key: fileKey,
    Body: fileBuffer,
  });

  await s3.send(command);

  return {
    key: fileKey,
    originalName,
    size: fileBuffer.length,
    type: path.extname(originalName).substring(1),
    location: `https://${bucketName}.s3.amazonaws.com/${fileKey}`,
  };
};



// Upload avec dossier_id
export const uploadFiles = async (req, res) => {
  const { dossier_id, entreprise_id } = req.body;

  if (!dossier_id) return res.status(400).json({ error: "ID du dossier requis" });
  if (!entreprise_id) return res.status(400).json({ error: "ID de l'entreprise requis" });

  try {
    const uploaded = [];

    for (const file of req.files) {

      if (!isAllowedExtension(file.originalname)) {
        console.warn(`Fichier ignoré (extension non autorisée) : ${file.originalname}`);
        continue;
      }
      let finalName = file.originalname;
      let finalPath = file.path;
      let isConverted = false;

      const convertedPath = await convertToPdf(file.path);

      if (convertedPath) {
        finalPath = convertedPath;
        finalName = path.basename(convertedPath);
        fs.unlinkSync(file.path); // on supprime l'original (ex : .docx)
        isConverted = true;
      }

      const finalBuffer = fs.readFileSync(finalPath);

      const contenu_ocr = await extractSmartText(finalPath);
      const encryptedBuffer = await encryptionService.encryptFile(finalBuffer, finalName, entreprise_id);
      const jsonString = encryptedBuffer.toString('utf8');
      const s3Data = await uploadFileBufferToS3(encryptedBuffer, finalName + '.enc');

      uploaded.push([
        s3Data.originalName,
        s3Data.location,
        s3Data.type,
        s3Data.size,
        dossier_id,
        contenu_ocr,
        // jsonString
      ]);

      if (isConverted) {
        fs.unlinkSync(finalPath); // ici, on supprime le PDF converti
      }
      if (!isConverted && fs.existsSync(finalPath)) {
        fs.unlinkSync(finalPath); // supprime les fichiers non convertis (images, pdf, etc.)
      }

    }

    const placeholders = uploaded.map((_, i) =>
      `($${i * 6 + 1}, $${i * 6 + 2}, $${i * 6 + 3}, $${i * 6 + 4}, $${i * 6 + 5}, $${i * 6 + 6})`
    ).join(', ');

    const query = `
      INSERT INTO fichiers (nom, chemin, type, taille, dossier_id, contenu_ocr)
      VALUES ${placeholders}
      RETURNING *;
    `;

    const flatValues = uploaded.flat();
    const result = await pool.query(query, flatValues);

    res.status(200).json({ fichiers: result.rows });

  } catch (err) {
    console.error("Erreur détaillée lors du téléversement des fichiers :", err);
    res.status(500).json({ error: 'Erreur lors du téléversement des fichiers' });
  }
};
