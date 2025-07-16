import { PDFDocument } from 'pdf-lib';
import pdfParse from 'pdf-parse';
import sharp from 'sharp';
import Tesseract from 'tesseract.js';

// Extrait le texte d'un PDF classique via pdf-parse (buffer)
async function extractTextFromPdfBuffer(pdfBuffer) {
  const data = await pdfParse(pdfBuffer);
  return data.text;
}

// Convertit une page PDF (buffer) en image PNG buffer puis OCR via Tesseract
async function ocrPageBuffer(pdfPageBuffer) {
  // Convertir PDF page en PNG avec sharp
  const imageBuffer = await sharp(pdfPageBuffer).png().toBuffer();

  // OCR en mémoire via tesseract.js
  const { data: { text } } = await Tesseract.recognize(imageBuffer, 'fra'); // ou 'eng'
  return text;
}

// OCR complet pour PDF scanné : chaque page convertie en image et OCR
async function extractTextFromScannedPdfBuffer(pdfBuffer) {
  const pdfDoc = await PDFDocument.load(pdfBuffer);
  const numPages = pdfDoc.getPageCount();

  let fullText = '';

  for (let i = 0; i < numPages; i++) {
    const newPdf = await PDFDocument.create();
    const [copiedPage] = await newPdf.copyPages(pdfDoc, [i]);
    newPdf.addPage(copiedPage);

    const singlePagePdfBytes = await newPdf.save();

    const pageText = await ocrPageBuffer(singlePagePdfBytes);
    fullText += `Page ${i + 1}:\n${pageText}\n\n`;
  }

  return fullText.trim();
}

// OCR image en mémoire via buffer
async function extractTextFromImageBuffer(imageBuffer) {
  try {
    // Essayer de traiter l'image avec Sharp d'abord
    const processedBuffer = await sharp(imageBuffer)
      .jpeg() // Convertir en JPEG pour assurer la compatibilité
      .toBuffer();
    
    const { data: { text } } = await Tesseract.recognize(processedBuffer, 'fra'); // ou 'eng'
    return text.trim();
  } catch (sharpError) {
    console.error('Erreur Sharp lors du traitement de l\'image:', sharpError);
    
    // Si Sharp échoue, essayer directement avec Tesseract
    try {
      const { data: { text } } = await Tesseract.recognize(imageBuffer, 'fra');
      return text.trim();
    } catch (tesseractError) {
      console.error('Erreur Tesseract lors du traitement de l\'image:', tesseractError);
      return ''; // Retourner une chaîne vide en cas d'échec
    }
  }
}

// Fonction principale qui choisit la bonne méthode en fonction de l'extension
export async function extractSmartText(buffer, fileName) {
  const ext = fileName.toLowerCase().split('.').pop();

  if (ext === 'pdf') {
    const rawText = await extractTextFromPdfBuffer(buffer);
    if (rawText.trim().length > 20) {
      return rawText.trim();
    } else {
      return await extractTextFromScannedPdfBuffer(buffer);
  }
  }

  if (['jpg', 'jpeg', 'png', 'bmp', 'tiff'].includes(ext)) {
    return await extractTextFromImageBuffer(buffer);
  }

  return ''; // Format non supporté
}
