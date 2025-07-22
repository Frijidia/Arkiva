import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PDFDocument } from 'pdf-lib';
// import { s3, bucket } from '../config/s3.js'; // s3 client configuré
import downloadFileBufferFromS3 from '../fichiers/fichierControllers.js'; // utilitaire pour convertir ReadableStream
import encryptionService from '../encryption/encryptionService.js';
import { extractSmartText } from '../ocr/ocrControllers.js'
import { uploadFileBufferToS3 } from '../upload/uploadControllers.js'
import pool from '../../config/database.js';
import fs from 'fs';

// import { PDFDocument } from 'pdf-lib';

export const mergePdfs = async (req, res) => {
  const { fichiers, entreprise_id, dossier_id, fileName } = req.body;

  try {
    const mergedPdf = await PDFDocument.create();
    const A4_WIDTH = 595.28;
    const A4_HEIGHT = 841.89;

    for (const chemin of fichiers) {
      const s3BaseUrl = 'https://arkivabucket.s3.amazonaws.com/';
      const key = chemin.replace(s3BaseUrl, '');

      const encryptedBuffer = await downloadFileBufferFromS3(key);
      const { content: decryptedBuffer, originalFileName } = await encryptionService.decryptFile(encryptedBuffer, entreprise_id);

      const ext = originalFileName.toLowerCase();

      // Log taille du buffer déchiffré
      console.log('Nom:', originalFileName, 'Taille buffer déchiffré:', decryptedBuffer?.length);

      if (!decryptedBuffer || decryptedBuffer.length < 100) {
        console.warn(`Fichier ${originalFileName} vide ou trop petit, ignoré.`);
        continue;
      }

      try {
        if (ext.endsWith('.pdf')) {
          let pdf;
          try {
            pdf = await PDFDocument.load(decryptedBuffer);
            console.log('Nombre de pages dans', originalFileName, ':', pdf.getPageCount());
          } catch (e) {
            console.warn(`Impossible de charger le PDF ${originalFileName}:`, e);
            continue;
          }
          const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());

          for (const copiedPage of copiedPages) {
            mergedPdf.addPage(copiedPage);
          }

        } else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) {
          const imagePdf = await PDFDocument.create();
          let image;

          if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
            image = await imagePdf.embedJpg(decryptedBuffer);
          } else if (ext.endsWith('.png')) {
            image = await imagePdf.embedPng(decryptedBuffer);
          }

          // Crée une page A4 dans ce PDF
          const page = imagePdf.addPage([A4_WIDTH, A4_HEIGHT]);

          // Calcul échelle pour que l'image tienne dans la page A4
          const scale = Math.min(A4_WIDTH / image.width, A4_HEIGHT / image.height);
          const imgWidth = image.width * scale;
          const imgHeight = image.height * scale;

          // Centre l'image
          const x = (A4_WIDTH - imgWidth) / 2;
          const y = (A4_HEIGHT - imgHeight) / 2;

          page.drawImage(image, {
            x,
            y,
            width: imgWidth,
            height: imgHeight,
          });

          // Convertit le PDF image en bytes
          const imagePdfBytes = await imagePdf.save();

          // Recharge ce PDF temporaire pour copier la page dans mergedPdf
          const pdfFromImage = await PDFDocument.load(imagePdfBytes);
          const pages = await mergedPdf.copyPages(pdfFromImage, pdfFromImage.getPageIndices());

          pages.forEach(page => mergedPdf.addPage(page));

        } else {
          console.warn(`Format non supporté : ${originalFileName}, ignoré.`);
          continue;
        }
      } catch (error) {
        console.warn(`Erreur lors du traitement du fichier ${originalFileName}:`, error);
        continue;
      }
    }

    const finalPdfBytes = await mergedPdf.save();
    const base64Pdf = Buffer.from(finalPdfBytes).toString('base64');

    // Sauvegarde le PDF fusionné via ta fonction utilitaire
    const savedFile = await saveMergedPdfFile(entreprise_id, dossier_id, fileName, base64Pdf);

    res.setHeader('Content-Type', 'application/pdf');
    res.send(Buffer.from(finalPdfBytes));

  } catch (err) {
    console.error('Erreur fusion PDF', err);
    res.status(500).json({ error: 'Fusion échouée' });
  }
};




export async function saveMergedPdfFile(entreprise_id, dossier_id, fileName, base64Pdf) {

   if (!fileName || !dossier_id) {
    throw new Error('fileName et dossier_id sont requis pour sauvegarder le fichier');
  }
  
  const finalBuffer = Buffer.from(base64Pdf, 'base64');

  // Écriture locale pour debug
  try {
    fs.writeFileSync('/tmp/test_fusion.pdf', finalBuffer);
    console.log('PDF fusionné écrit dans /tmp/test_fusion.pdf');
  } catch (e) {
    console.error('Erreur lors de l\'écriture du PDF fusionné en local:', e);
  }

  const contenu_ocr =  await extractSmartText(finalBuffer, fileName + 'pdf'); // ou null
  const encryptedBuffer = await encryptionService.encryptFile(finalBuffer, fileName, entreprise_id);
  const s3Data = await uploadFileBufferToS3(encryptedBuffer, fileName + '.enc');

  const result = await pool.query(
    `INSERT INTO fichiers (nom, chemin, type, taille, dossier_id, contenu_ocr, originalFileName)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
    [
      s3Data.originalName,
      s3Data.location,
      s3Data.type,
      s3Data.size,
      dossier_id,
      contenu_ocr,
      fileName,
    ]
  );
  return result.rows[0];

};




export const mergeSelectedPages = async (req, res) => {
  const { fichiers, entreprise_id, dossier_id, fileName } = req.body;

  if (!fichiers || !Array.isArray(fichiers) || fichiers.length === 0 || !entreprise_id) {
    return res.status(400).json({ error: "Paramètres invalides. Assurez-vous d'envoyer fichiers[], entreprise_id." });
  }

  try {
    const mergedPdf = await PDFDocument.create();
    const fichiersIgnores = [];

    for (const fichier of fichiers) {
      const { chemin, pages } = fichier;
      const s3BaseUrl = 'https://arkivabucket.s3.amazonaws.com/';
      const key = chemin.replace(s3BaseUrl, '');

      try {
        const encryptedBuffer = await downloadFileBufferFromS3(key);
        const { content: decryptedBuffer, originalFileName } = await encryptionService.decryptFile(encryptedBuffer, entreprise_id);

        const ext = originalFileName.toLowerCase();
        if (!ext.endsWith('.pdf')) {
          fichiersIgnores.push(originalFileName);
          continue;
        }

        const pdf = await PDFDocument.load(decryptedBuffer);
        const totalPages = pdf.getPageCount();

        const selectedIndices = (pages || [])
          .map(p => p - 1)
          .filter(i => i >= 0 && i < totalPages);

        const copiedPages = await mergedPdf.copyPages(pdf, selectedIndices);
        copiedPages.forEach(page => mergedPdf.addPage(page));
      } catch (err) {
        console.warn(`Erreur avec le fichier ${chemin}:`, err.message);
        fichiersIgnores.push(chemin);
        continue;
      }
    }

    const finalPdfBytes = await mergedPdf.save();
    const base64Pdf = Buffer.from(finalPdfBytes).toString('base64');

    // sauvegarder le PDF fusionné, vérifier que dossier_id et fileName sont présents
      const savedFile = await  saveMergedPdfFile(entreprise_id, dossier_id, fileName, base64Pdf);

    const message = fichiersIgnores.length > 0
      ? `Fusion terminée. Les fichiers suivants ont été ignorés : ${fichiersIgnores.join(', ')}`
      : 'Fusion terminée avec succès.';

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'inline; filename="fusion.pdf"');
    res.setHeader('X-Message', message); // Optionnel : pour message dans le header

    res.send(Buffer.from(finalPdfBytes));
  } catch (error) {
    console.error('Erreur fusion avec sélection de pages :', error.message);
    res.status(500).json({ error: "Fusion échouée lors de l'extraction des pages." });
  }
};

export const getPdfPageCount = async (req, res) => {
  const { chemin, entreprise_id } = req.body;

  if (!chemin || !entreprise_id) {
    return res.status(400).json({ error: 'Paramètres invalides. Assurez-vous d\'envoyer chemin et entreprise_id.' });
  }

  try {
    const s3BaseUrl = 'https://arkivabucket.s3.amazonaws.com/';
    const key = chemin.replace(s3BaseUrl, '');

    // Télécharger et déchiffrer
    const encryptedBuffer = await downloadFileBufferFromS3(key);
    const { content: decryptedBuffer } = await encryptionService.decryptFile(encryptedBuffer, entreprise_id);

    const pdf = await PDFDocument.load(decryptedBuffer);
    const totalPages = pdf.getPageCount();

    res.json({ pageCount: totalPages });
  } catch (error) {
    console.error('Erreur récupération nombre de pages :', error);
    res.status(500).json({ error: 'Impossible de récupérer le nombre de pages' });
  }
};
