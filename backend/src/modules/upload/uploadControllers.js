import multer from 'multer';
import multerS3 from 'multer-s3';
import { PutObjectCommand } from '@aws-sdk/client-s3';
import s3 from '../../config/aws.js';  
import pool from '../../config/database.js';
import { exec } from 'child_process';
import fs from 'fs';
import path from 'path';
import libre from 'libreoffice-convert';
import { promisify } from 'util';


const convert = promisify(libre.convert);
const bucketName = process.env.AWS_S3_BUCKET_NAME;  // ton bucket S3


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

export const  upload = multer({ storage });


// fonction pour send sur aws
export const uploadFileToS3 = async (filePath, originalName) => {
  const fileContent = fs.readFileSync(filePath);
  const fileKey = 'uploads/' + Date.now() + '-' + path.basename(filePath);

  const command = new PutObjectCommand({
    Bucket: bucketName,
    Key: fileKey,
    Body: fileContent,
  });

  await s3.send(command);

  return {
    key: fileKey,
    originalName,
    size: fileContent.length,
    type: path.extname(filePath).substring(1),
    location: `https://${bucketName}.s3.amazonaws.com/${fileKey}`,
  };
};


// Upload avec dossier_id
export const uploadFiles = async (req, res) => {
  const { dossier_id } = req.body;

  if (!dossier_id) return res.status(400).json({ error: "ID du dossier requis" });

  try {
    const uploaded = [];

    for (const file of req.files) {
      let finalPath = file.path;
      let finalName = file.originalname;

      const convertedPath = await convertToPdf(file.path);
      if (convertedPath) {
        finalPath = convertedPath;
        finalName = path.basename(convertedPath);
        fs.unlinkSync(file.path); // Nettoie le .docx
      }

      const s3Data = await uploadFileToS3(finalPath, finalName);
      fs.unlinkSync(finalPath); // Nettoie le PDF aussi

      uploaded.push([
        s3Data.originalName,
        s3Data.location,
        s3Data.type,
        s3Data.size,
        dossier_id,
      ]);
    }

    const placeholders = uploaded.map((_, i) =>
      `($${i * 5 + 1}, $${i * 5 + 2}, $${i * 5 + 3}, $${i * 5 + 4}, $${i * 5 + 5})`
    ).join(', ');

    const query = `
      INSERT INTO fichiers (nom, chemin, type, taille, dossier_id)
      VALUES ${placeholders}
      RETURNING *;
    `;
    const flatValues = uploaded.flat();
    const result = await pool.query(query, flatValues);

    res.status(200).json({ fichiers: result.rows });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du téléversement des fichiers' });
  }
};


