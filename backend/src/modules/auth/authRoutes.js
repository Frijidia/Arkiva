import express from 'express';
// import authMiddlewares from './authMiddleware.js'


import {
    register,
    login,
    getUsers,
   
  } from './authController.js';
  
const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/getuser',getUsers);

// Exportation du router avec ES Modules
export default router;
