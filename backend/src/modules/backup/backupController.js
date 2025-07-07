import backupModel from './backupModel.js';
import backupService from './backupService.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import archiver from 'archiver';
import pool from '../../config/database.js';
import { v4 as uuidv4 } from 'uuid';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Contrôleurs pour les sauvegardes
export const createBackup = async (req, res) => {
    try {
        console.log('Requête reçue pour création de sauvegarde :', req.body);
        const { type, cible_id, entreprise_id } = req.body;

        if (!type || !cible_id || !entreprise_id) {
            return res.status(400).json({ error: 'Type, cible_id et entreprise_id sont requis' });
        }

        // Utiliser le service de sauvegarde S3
        const backupData = {
            type,
            cible_id,
            entreprise_id,
            mode: 'automatic'
        };

        await backupService.createBackup(backupData, req.user?.user_id, res);

    } catch (error) {
        console.error('Erreur lors de la création de la sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
};

// Fonction utilitaire pour convertir un ID en UUID
const convertToUuid = async (id) => {
    try {
        // Si l'ID est déjà un UUID valide, le retourner tel quel
        if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
            return id;
        }
        // Sinon, générer un nouvel UUID
        return uuidv4();
    } catch (error) {
        console.error('Erreur lors de la conversion en UUID:', error);
        throw error;
    }
};

export const getAllBackups = async (req, res) => {
    try {
        const backups = await backupModel.getAllBackups();
        res.json(backups);
    } catch (error) {
        console.error('Erreur lors de la récupération des sauvegardes:', error);
        res.status(500).json({ error: error.message });
    }
};

export const getBackupById = async (req, res) => {
    try {
        const backup = await backupModel.getBackupById(req.params.id);
        if (!backup) {
            return res.status(404).json({ error: 'Sauvegarde non trouvée' });
        }
        res.json(backup);
    } catch (error) {
        console.error('Erreur lors de la récupération de la sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
}; 