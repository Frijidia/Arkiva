
import express from 'express';
// import multer from 'multer';
import { uploadFiles } from './uploadControllers.js';
import { upload } from './uploadControllers.js';

const router = express.Router();
// const upload = multer({ storage: multer.memoryStorage() }); // mémoire temporaire

router.post('/', upload.array('files', 10), uploadFiles);

export default router;

