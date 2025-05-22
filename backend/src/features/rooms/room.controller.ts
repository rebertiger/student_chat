import { Request, Response } from 'express';
import { Server as SocketIOServer } from 'socket.io';
import pool, { query as executeQuery } from '../../db'; // Updated import

// Get all public rooms
export const getRooms = async (req: Request, res: Response) => {
    try {
        const roomsResult = await executeQuery(
            `SELECT r.room_id, r.room_name, r.is_public, r.created_at, r.creator_full_name,
                    s.name AS subject_name,
                    u.user_id AS creator_user_id, u.full_name AS creator_full_name
             FROM rooms r
             LEFT JOIN subjects s ON r.subject_id = s.subject_id
             LEFT JOIN users u ON r.created_by = u.user_id
             WHERE r.is_public = true
             ORDER BY r.created_at DESC`
        );

        const rooms = roomsResult.rows.map(room => ({
            room_id: room.room_id,
            room_name: room.room_name,
            is_public: room.is_public,
            created_at: room.created_at,
            creator_full_name: room.creator_full_name, // This might be redundant if creator relation is preferred
            subject: room.subject_name ? { name: room.subject_name } : null,
            creator: room.creator_user_id ? { user_id: room.creator_user_id, full_name: room.creator_full_name } : null
        }));

        res.status(200).json(rooms);
    } catch (error) {
        console.error('Error fetching rooms:', error);
        res.status(500).json({ message: 'Internal server error fetching rooms.' });
    }
};

// Create a new room
export const createRoom = async (req: Request, res: Response) => {
    const { room_name, subject_id, is_public, creator_full_name } = req.body;
    const created_by_user_id = req.user?.user_id; // Get from authenticated user

    if (!created_by_user_id) {
        return res.status(401).json({ message: 'User not authenticated to create a room.' });
    }

    if (!room_name) {
        return res.status(400).json({ message: 'Room name is required.' });
    }

    const actualCreatorFullName = creator_full_name || req.user?.full_name || 'Anonymous';

    try {
        const newRoomResult = await executeQuery(
            `INSERT INTO rooms (room_name, subject_id, is_public, created_by, creator_full_name)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING room_id, room_name, subject_id, is_public, created_by, created_at, creator_full_name`,
            [room_name, subject_id ? parseInt(subject_id, 10) : null, is_public !== undefined ? Boolean(is_public) : true, created_by_user_id, actualCreatorFullName]
        );

        const newRoom = newRoomResult.rows[0];

        // Fetch creator details for the response (if not already part of req.user)
        const creatorDetails = req.user ? { user_id: req.user.user_id, full_name: req.user.full_name } : null;
        
        // Automatically add the creator as a participant
        await executeQuery(
            'INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)',
            [newRoom.room_id, created_by_user_id]
        );

        res.status(201).json({ 
            message: 'Room created successfully', 
            room: { ...newRoom, creator: creatorDetails }
        });

    } catch (error) {
        console.error('Error creating room:', error);
        if (error instanceof Error && (error as any).code === '23503') { // foreign key violation
             return res.status(400).json({ message: 'Invalid subject ID provided.' });
        }
        res.status(500).json({ message: 'Internal server error creating room.' });
    }
};

// Get details for a specific room
export const getRoomById = async (req: Request, res: Response) => {
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        const roomResult = await executeQuery(
            `SELECT r.*, s.name as subject_name, s.description as subject_description, 
                    u.user_id as creator_user_id, u.full_name as creator_full_name
             FROM rooms r
             LEFT JOIN subjects s ON r.subject_id = s.subject_id
             LEFT JOIN users u ON r.created_by = u.user_id
             WHERE r.room_id = $1`,
            [roomId]
        );

        if (roomResult.rows.length === 0) {
            return res.status(404).json({ message: 'Room not found.' });
        }

        const roomData = roomResult.rows[0];

        const participantsResult = await executeQuery(
            `SELECT rp.user_id, u.full_name
             FROM room_participants rp
             JOIN users u ON rp.user_id = u.user_id
             WHERE rp.room_id = $1`,
            [roomId]
        );

        const room = {
            ...roomData,
            subject: roomData.subject_id ? { subject_id: roomData.subject_id, name: roomData.subject_name, description: roomData.subject_description } : null,
            creator: roomData.creator_user_id ? { user_id: roomData.creator_user_id, full_name: roomData.creator_full_name } : null,
            participants: participantsResult.rows.map(p => ({ user: { user_id: p.user_id, full_name: p.full_name }}))
        };
        
        // TODO: Add authorization check - is user allowed to see this room?

        res.status(200).json(room);
    } catch (error) {
        console.error(`Error fetching room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error fetching room details.' });
    }
};

// Join a room
export const joinRoom = async (req: Request, res: Response) => {
    const userId = req.user?.user_id;
    const roomId = parseInt(req.params.roomId, 10);

    if (!userId) {
        return res.status(401).json({ message: 'User not authenticated.' });
    }
    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        const roomExistsResult = await executeQuery('SELECT 1 FROM rooms WHERE room_id = $1', [roomId]);
        if (roomExistsResult.rows.length === 0) {
            return res.status(404).json({ message: 'Room not found.' });
        }

        const existingParticipantResult = await executeQuery(
            'SELECT 1 FROM room_participants WHERE room_id = $1 AND user_id = $2',
            [roomId, userId]
        );

        if (existingParticipantResult.rows.length > 0) {
            return res.status(200).json({ message: 'Already joined this room.' });
        }

        await executeQuery(
            'INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)',
            [roomId, userId]
        );

        res.status(200).json({ message: 'Successfully joined the room.' });

    } catch (error) {
        console.error(`Error joining room ${roomId} for user ${userId}:`, error);
        res.status(500).json({ message: 'Internal server error joining room.' });
    }
};

// Get messages for a specific room
export const getMessagesForRoom = async (req: Request, res: Response) => {
    const userId = req.user?.user_id; // For authorization check
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }
    if (!userId) {
        return res.status(401).json({ message: 'User not authenticated.'});
    }

    try {
        // Optional: Verify user is participant first
        const participantResult = await executeQuery(
            'SELECT 1 FROM room_participants WHERE room_id = $1 AND user_id = $2',
            [roomId, userId]
        );
        if (participantResult.rows.length === 0) {
            // If room is public, allow viewing messages. If private, deny.
            const roomPrivacyResult = await executeQuery('SELECT is_public FROM rooms WHERE room_id = $1', [roomId]);
            if (roomPrivacyResult.rows.length === 0 || !roomPrivacyResult.rows[0].is_public) {
                 return res.status(403).json({ message: 'Access denied. You are not in this private room.' });
            }
        }

        const messagesResult = await executeQuery(
            `SELECT m.message_id, m.room_id, m.sender_id, m.message_type, m.message_text, m.file_url, m.sent_at, m.is_edited,
                    u.user_id AS sender_user_id, u.full_name AS sender_full_name
             FROM messages m
             LEFT JOIN users u ON m.sender_id = u.user_id
             WHERE m.room_id = $1
             ORDER BY m.sent_at ASC`,
            [roomId]
        );

        const messages = messagesResult.rows.map(msg => ({
            ...msg,
            sender: msg.sender_user_id ? { user_id: msg.sender_user_id, full_name: msg.sender_full_name } : null
        }));

        res.status(200).json(messages);

    } catch (error) {
         console.error(`Error fetching messages for room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error fetching messages.' });
    }
};

// Handle file upload for a room
export const uploadFile = async (req: Request, res: Response) => {
    const userId = req.user?.user_id;
    const roomId = parseInt(req.params.roomId, 10);

    if (!userId || !req.user?.full_name) {
        return res.status(401).json({ message: 'User not authenticated or user details missing.' });
    }
    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }
    if (!req.file) {
        return res.status(400).json({ message: 'No file uploaded.' });
    }

    try {
        // Optional: Verify user is participant first
        const participantResult = await executeQuery('SELECT 1 FROM room_participants WHERE room_id = $1 AND user_id = $2', [roomId, userId]);
        if (participantResult.rows.length === 0) {
            const roomPrivacyResult = await executeQuery('SELECT is_public FROM rooms WHERE room_id = $1', [roomId]);
            if (roomPrivacyResult.rows.length === 0 || !roomPrivacyResult.rows[0].is_public) {
                return res.status(403).json({ message: 'Access denied. You cannot upload to this private room.' });
            }
        }

        const file = req.file;
        const fileUrl = `/uploads/${file.filename}`;
        const messageType = file.mimetype.startsWith('image/') ? 'image' : (file.mimetype === 'application/pdf' ? 'pdf' : 'file');

        const newMessageResult = await executeQuery(
            `INSERT INTO messages (room_id, sender_id, message_type, message_text, file_url)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING message_id, room_id, sender_id, message_type, message_text, file_url, sent_at, is_edited`,
            [roomId, userId, messageType, file.originalname, fileUrl]
        );

        const newMessage = {
            ...newMessageResult.rows[0],
            sender: { user_id: userId, full_name: req.user.full_name } // Add sender info for broadcast
        };

        const roomIdentifier = `room_${roomId}`;
        const io = req.app.get('io') as SocketIOServer;
        io.to(roomIdentifier).emit('newMessage', newMessage);
        console.log(`File message broadcasted to room ${roomIdentifier}`);

        res.status(201).json({ message: 'File uploaded successfully', messageData: newMessage });

    } catch (error) {
        console.error(`Error uploading file for room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error uploading file.' });
    }
};
