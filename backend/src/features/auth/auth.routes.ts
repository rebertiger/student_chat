import express from 'express';
import { register, login, deleteUser } from './auth.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = express.Router();

// POST /api/auth/register
router.post('/register', register);

// POST /api/auth/login
router.post('/login', login);

// DELETE /api/auth/delete
router.delete('/delete', authenticateToken, deleteUser);

export default router;
