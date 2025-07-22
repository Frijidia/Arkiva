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
  
  // Si c'est déjà un PDF, pas besoin de conversion
  if (fileExt === '.pdf') {
    return filePath;
  }
  
  // Convertir les documents Office en PDF
  if (['.doc', '.docx', '.txt'].includes(fileExt)) {
    try {
      const file = fs.readFileSync(filePath);
      const outputPath = filePath.replace(fileExt, '.pdf');

      const pdfBuf = await convert(file, '.pdf', undefined);
      fs.writeFileSync(outputPath, pdfBuf);

      return outputPath;
    } catch (error) {
      console.error('Erreur lors de la conversion en PDF:', error);
      return null;
    }
  }
  
  // Pour les images, on peut les convertir en PDF si nécessaire
  if (['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp'].includes(fileExt)) {
    try {
      // Créer un PDF simple avec l'image
      const outputPath = filePath.replace(fileExt, '.pdf');
      await createPdfFromImage(filePath, outputPath);
      return outputPath;
    } catch (error) {
      console.error('Erreur lors de la conversion d\'image en PDF:', error);
      return null;
    }
  }
  
  return null;
};

// Fonction pour créer un PDF à partir d'une image
const createPdfFromImage = async (imagePath, outputPath) => {
  try {
    // Utiliser une bibliothèque comme pdf-lib pour créer un PDF avec l'image
    const { PDFDocument, PDFImage } = await import('pdf-lib');
    const fs = await import('fs');
    
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([595, 842]); // Format A4
    
    // Lire l'image
    const imageBytes = fs.readFileSync(imagePath);
    let image;
    
    const ext = path.extname(imagePath).toLowerCase();
    if (['.jpg', '.jpeg'].includes(ext)) {
      image = await pdfDoc.embedJpg(imageBytes);
    } else if (['.png'].includes(ext)) {
      image = await pdfDoc.embedPng(imageBytes);
    } else {
      throw new Error('Format d\'image non supporté pour la conversion PDF');
    }
    
    // Calculer les dimensions pour centrer l'image
    const { width, height } = image.scale(1);
    const pageWidth = page.getWidth();
    const pageHeight = page.getHeight();
    
    const scaleX = pageWidth / width;
    const scaleY = pageHeight / height;
    const scale = Math.min(scaleX, scaleY) * 0.9; // 90% de la page
    
    const scaledWidth = width * scale;
    const scaledHeight = height * scale;
    const x = (pageWidth - scaledWidth) / 2;
    const y = (pageHeight - scaledHeight) / 2;
    
    page.drawImage(image, {
      x,
      y,
      width: scaledWidth,
      height: scaledHeight,
    });
    
    const pdfBytes = await pdfDoc.save();
    fs.writeFileSync(outputPath, pdfBytes);
    
    return outputPath;
  } catch (error) {
    console.error('Erreur lors de la création du PDF:', error);
    throw error;
  }
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
export async function  uploadFileBufferToS3 (fileBuffer, originalName){
  const fileKey = 'uploads/' + Date.now() + '-' + originalName;
  let fichiersTailleTotale = 0;

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
  let originalFileName = "";
  let fichiersTailleTotale = "";

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
      console.log(finalPath);
      let isConverted = false;

      const convertedPath = await convertToPdf(file.path);

      if (convertedPath) {
        finalPath = convertedPath;
        finalName = path.basename(convertedPath);
        fs.unlinkSync(file.path); // on supprime l'original (ex : .docx)
        isConverted = true;
      }

      const finalBuffer = fs.readFileSync(finalPath);

      // Gérer les erreurs d'OCR de manière plus robuste
      let contenu_ocr = "";
      try {
        contenu_ocr = await extractSmartText(finalBuffer, finalName);
        console.log(`OCR réussi pour ${finalName}`);
      } catch (ocrError) {
        console.error(`Erreur OCR pour ${finalName}:`, ocrError);
        contenu_ocr = ""; // Utiliser une chaîne vide en cas d'erreur OCR
      }

      const encryptedBuffer = await encryptionService.encryptFile(finalBuffer, finalName, entreprise_id);
      const jsonString = encryptedBuffer.toString('utf8');
      const s3Data = await uploadFileBufferToS3(encryptedBuffer, finalName + '.enc');
      fichiersTailleTotale += s3Data.size;

      uploaded.push([
        s3Data.originalName,
        s3Data.location,
        s3Data.type,
        s3Data.size,
        dossier_id,
        contenu_ocr,
        originalFileName = finalName
      ]);

      if (isConverted) {
        fs.unlinkSync(finalPath); // ici, on supprime le PDF converti
      }
      if (!isConverted && fs.existsSync(finalPath)) {
        fs.unlinkSync(finalPath); // supprime les fichiers non convertis (images, pdf, etc.)
      }

    }

    if (uploaded.length === 0) {
      return res.status(400).json({ error: "Aucun fichier valide à uploader" });
    }

    const checkEspace = await checkArmoireStorageCapacity(dossier_id, fichiersTailleTotale);
    if (!checkEspace.peutAjouter) {
      return res.status(400).json({
        error: checkEspace.message,
        totalActuel: checkEspace.totalActuel,
        fichiersTailleTotale: checkEspace.fichiersTailleTotale,
        espaceRestant: checkEspace.nouvelleTailleTotale,
      });
    }

    const placeholders = uploaded.map((_, i) =>
      `($${i * 7 + 1}, $${i * 7 + 2}, $${i * 7 + 3}, $${i * 7 + 4}, $${i * 7 + 5}, $${i * 7 + 6},  $${i * 7 + 7})`
    ).join(', ');

    const query = `
      INSERT INTO fichiers (nom, chemin, type, taille, dossier_id, contenu_ocr, originalfilename)
      VALUES ${placeholders}
      RETURNING *
    `;

    const flatValues = uploaded.flat();
    const result = await pool.query(query, flatValues);

    res.status(200).json({ fichiers: result.rows });

  } catch (err) {
    console.error("Erreur détaillée lors du téléversement des fichiers :", err);
    res.status(500).json({ error: 'Erreur lors du téléversement des fichiers' });
  }
};


async function checkArmoireStorageCapacity(dossier_id, fichiersTailleTotale) {
  // 1. Récupérer armoire_id et taille_max à partir du dossier
  const armoireResult = await pool.query(`
    SELECT armoires.armoire_id, armoires.taille_max
    FROM dossiers
    JOIN casiers ON dossiers.cassier_id = casiers.cassier_id
    JOIN armoires ON casiers.armoire_id = armoires.armoire_id
    WHERE dossiers.dossier_id = $1
  `, [dossier_id]);

  if (armoireResult.rows.length === 0) {
    throw new Error("Armoire liée non trouvée pour ce dossier.");
  }

  const { armoire_id, taille_max } = armoireResult.rows[0];

  if (taille_max === null || taille_max === undefined) {
    throw new Error("La capacité maximale de l'armoire n'est pas définie.");
  }

  const tailleMaxNumber = Number(taille_max);
  if (isNaN(tailleMaxNumber)) {
    throw new Error("La capacité maximale de l'armoire n'est pas un nombre valide.");
  }

  // 2. Calculer la taille totale déjà utilisée dans cette armoire
  const totalResult = await pool.query(`
    SELECT COALESCE(SUM(fichiers.taille), 0) AS total_octets
    FROM fichiers
    JOIN dossiers ON fichiers.dossier_id = dossiers.dossier_id
    JOIN casiers ON dossiers.cassier_id = casiers.cassier_id
    WHERE casiers.armoire_id = $1
      AND fichiers.is_deleted = false
  `, [armoire_id]);

  const totalActuel = Number(totalResult.rows[0].total_octets) || 0;
  const nouvelleTailleTotale = Number(totalActuel) + Number(fichiersTailleTotale);


  // 3. Calcul de l'espace restant
  const espaceRestant = tailleMaxNumber - totalActuel;

  // 4. Comparaison et retour d'infos
  if (nouvelleTailleTotale >= tailleMaxNumber) {
    return {
      peutAjouter: false,
      totalActuel,
      fichiersTailleTotale,
      nouvelleTailleTotale,
      message: "La limite de stockage de l'armoire sera dépassée."
    };
  }

  return {
    peutAjouter: true,
    espaceRestant: espaceRestant - fichiersTailleTotale,
    message: "Espace suffisant pour ajouter les fichiers."
  };
}
