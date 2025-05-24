import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';
import {
  getAllSubjects,
  addSubject,
  getUserSubjects,
  addUserSubject,
  removeUserSubject
} from './subjects.controller';

const router = Router();

// List all subjects
router.get('/', authenticateToken, getAllSubjects);
// Add a new subject (optional, admin only)
router.post('/', authenticateToken, addSubject);
// List current user's subjects
router.get('/user', authenticateToken, getUserSubjects);
// Add a subject to current user
router.post('/user', authenticateToken, addUserSubject);
// Remove a subject from current user
router.delete('/user/:subjectId', authenticateToken, removeUserSubject);

export default router; 