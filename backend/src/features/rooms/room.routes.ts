import { Router } from 'express';
import { getRooms, createRoom, getRoomById, joinRoom, getMessagesForRoom, uploadFile, deleteRoom } from './room.controller'; // Add deleteRoom
import { upload } from '../../middleware/multer.config'; // Correct import path for upload middleware
import { authenticateToken } from '../../middleware/auth.middleware';

// TODO: Import authentication middleware later

const router = Router();

// GET /api/rooms - Get list of public rooms
// TODO: Add auth middleware if needed to get user-specific rooms
router.get('/', authenticateToken, getRooms);

// POST /api/rooms - Create a new room
// TODO: Add auth middleware to protect this route and get user ID
router.post('/', authenticateToken, createRoom);

// GET /api/rooms/:roomId - Get details for a specific room
// TODO: Add auth middleware to check if user can access the room
router.get('/:roomId', authenticateToken, getRoomById);

// POST /api/rooms/:roomId/join - Join a specific room
// TODO: Add auth middleware
router.post('/:roomId/join', authenticateToken, joinRoom);

// GET /api/rooms/:roomId/messages - Get messages for a specific room
// TODO: Add auth middleware
router.get('/:roomId/messages', authenticateToken, getMessagesForRoom);

// POST /api/rooms/:roomId/files - Upload a file to a room
// TODO: Add auth middleware
router.post('/:roomId/files', authenticateToken, upload.single('file'), uploadFile); // Use upload middleware for single file named 'file'

// DELETE /api/rooms/:roomId - Delete a room (only by creator)
router.delete('/:roomId', authenticateToken, deleteRoom);

// TODO: Add routes for leaving a room, etc.

export default router;
