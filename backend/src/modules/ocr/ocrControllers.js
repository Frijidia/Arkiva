import fs from "fs";
import pdf from "pdf-parse";
import { fromPath } from "pdf2pic";
import Tesseract from "tesseract.js";
import pool from '../../config/database.js';


async function extractTextFromPdf (pdfPath)  {
  const dataBuffer =  fs.readFileSync(pdfPath);
  const data =  await pdf(dataBuffer);
  return data.text;
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



export const extractSmartText = async (pdfPath) => {
  const rawText = await extractTextFromPdf(pdfPath);

//   // Si texte extrait > 20 caractères, on considère que c'est un PDF texte
  if (rawText.trim().length > 20) {
    return rawText.trim();
  } else {
    // Sinon, PDF scanné, on fait de l'OCR
    return await extractTextFromScannedPdf(pdfPath);
  }
};


export const searchFichiersByOcrContent = async (req, res) => {
  const { searchTerm } = req.params;

  if (!searchTerm) {
    return res.status(400).json({ error: "Le paramètre 'searchTerm' est obligatoire." });
  }

  try {
    const query = `
      SELECT *
      FROM fichiers
      WHERE contenu_ocr ILIKE '%' || $1 || '%'
    `;

    const { rows } = await pool.query(query, [searchTerm]);

    res.status(200).json(rows);
  } catch (error) {
    console.error('Erreur recherche OCR:', error);
    res.status(500).json({ error: "Erreur lors de la recherche dans le contenu OCR." });
  }
};

