import { Router } from 'express';
import { getMessages, createMessage, reportMessage, getMessageCount } from './message.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// GET /api/messages/:roomId - Get messages for a specific room
router.get('/:roomId', authenticateToken, getMessages);

// POST /api/messages/:roomId - Create a new message
router.post('/:roomId', authenticateToken, createMessage);

// POST /api/messages/:messageId/report - Report a message
router.post('/:messageId/report', authenticateToken, reportMessage);

// GET /api/messages/:roomId/count - Get total message count for a room
router.get('/:roomId/count', authenticateToken, getMessageCount);

export default router;