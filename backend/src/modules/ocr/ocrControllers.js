import fs from "fs";
import pdf from "pdf-parse";
import { fromPath } from "pdf2pic";
import Tesseract from "tesseract.js";
import pool from '../../config/database.js';
import path from "path";

async function extractTextFromPdf(pdfPath) {
  const dataBuffer = fs.readFileSync(pdfPath);
  const data = await pdf(dataBuffer);
  return data.text;
};


export const extractTextFromImage = async (imagePath) => {
  const result = await Tesseract.recognize(imagePath, 'eng'); // ou 'fra' pour le français
  return result.data.text.trim();
};


async function extractTextFromScannedPdf(pdfPath) {
  // Récupérer nombre de pages avec pdf-parse
  const dataBuffer = fs.readFileSync(pdfPath);
  const data = "fdf"
  await pdf(dataBuffer);
  const numPages = data.numpages;

  const convert = fromPath(pdfPath, {
    density: 150,
    format: "png",
    width: 1200,
    height: 1600,
  });

  let fullText = "";

  for (let i = 1; i <= numPages; i++) {
    const page = await convert(i);
    const imagePath = page.path;

    const {
      data: { text },
    } = await Tesseract.recognize(imagePath, "fra"); // 'fra' ou 'eng'

    fullText += `Page ${i}:\n${text}\n\n`;

    fs.unlinkSync(imagePath);
  }

  return fullText.trim();
}



export const extractSmartText = async (filePath) => {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === '.pdf') {
    const rawText = await extractTextFromPdf(filePath);

    if (rawText.trim().length > 20) {
      return rawText.trim();
    } else {
      return await extractTextFromScannedPdf(filePath); // OCR du PDF scanné
    }
  }

  if (['.jpg', '.jpeg', '.png', '.bmp', '.tiff'].includes(ext)) {
    return await extractTextFromImage(filePath); // OCR direct sur l'image
  }

  return ''; // Format non pris en charge pour l’OCR
};

