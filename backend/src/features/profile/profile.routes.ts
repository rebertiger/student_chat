import { Router } from 'express';
import { getUserProfile, updateUserProfile } from './profile.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// GET /api/profile - Get user profile
// Kullanıcı kimlik doğrulaması gerekli
router.get('/', authenticateToken, getUserProfile);

// PUT /api/profile - Update user profile
// Kullanıcı kimlik doğrulaması gerekli
router.put('/', authenticateToken, updateUserProfile);

export default router;