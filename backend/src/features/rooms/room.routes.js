"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const room_controller_1 = require("./room.controller"); // Add uploadFile
const multer_config_1 = require("../../middleware/multer.config"); // Correct import path for upload middleware
// TODO: Import authentication middleware later
const router = (0, express_1.Router)();
// GET /api/rooms - Get list of public rooms
// TODO: Add auth middleware if needed to get user-specific rooms
router.get('/', room_controller_1.getRooms);
// POST /api/rooms - Create a new room
// TODO: Add auth middleware to protect this route and get user ID
router.post('/', room_controller_1.createRoom);
// GET /api/rooms/:roomId - Get details for a specific room
// TODO: Add auth middleware to check if user can access the room
router.get('/:roomId', room_controller_1.getRoomById);
// POST /api/rooms/:roomId/join - Join a specific room
// TODO: Add auth middleware
router.post('/:roomId/join', room_controller_1.joinRoom);
// GET /api/rooms/:roomId/messages - Get messages for a specific room
// TODO: Add auth middleware
router.get('/:roomId/messages', room_controller_1.getMessagesForRoom);
// POST /api/rooms/:roomId/files - Upload a file to a room
// TODO: Add auth middleware
router.post('/:roomId/files', multer_config_1.upload.single('file'), room_controller_1.uploadFile); // Use upload middleware for single file named 'file'
// TODO: Add routes for leaving a room, etc.
exports.default = router;
