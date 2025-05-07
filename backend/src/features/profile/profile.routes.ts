import { Router } from 'express';
import { getUserProfile, updateUserProfile } from './profile.controller';

// TODO: Import authentication middleware later

const router = Router();

// GET /api/profile - Get user profile
// TODO: Add auth middleware to protect this route and get user ID
router.get('/', getUserProfile);

// PUT /api/profile - Update user profile
// TODO: Add auth middleware to protect this route and get user ID
router.put('/', updateUserProfile);

export default router;