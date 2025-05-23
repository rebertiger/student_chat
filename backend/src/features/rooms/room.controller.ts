import { Request, Response } from 'express';
import { Server as SocketIOServer } from 'socket.io';
import pool from '../../db';

// Get all public rooms
export const getRooms = async (req: Request, res: Response) => {
    try {
        const result = await pool.query(
            `SELECT r.*, s.name as subject_name, u.full_name as creator_name
             FROM rooms r
             LEFT JOIN subjects s ON r.subject_id = s.subject_id
             LEFT JOIN users u ON r.created_by = u.user_id
             WHERE r.is_public = true
             ORDER BY r.created_at DESC`
        );

        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching rooms:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Create a new room
export const createRoom = async (req: Request, res: Response) => {
    const { room_name, subject_id, is_public } = req.body;
    const userId = req.user!.user_id;

    // Validate required fields
    if (!room_name) {
        return res.status(400).json({ message: 'Room name is required' });
    }

    try {
        // Get user's full name
        const userResult = await pool.query(
            'SELECT full_name FROM users WHERE user_id = $1',
            [userId]
        );

        const user = userResult.rows[0];
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Create room
        const roomResult = await pool.query(
            `INSERT INTO rooms (room_name, subject_id, is_public, created_by, creator_full_name)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [room_name, subject_id || null, is_public ?? true, userId, user.full_name]
        );

        const newRoom = roomResult.rows[0];

        // Add creator as participant
        await pool.query(
            `INSERT INTO room_participants (room_id, user_id)
             VALUES ($1, $2)`,
            [newRoom.room_id, userId]
        );

        // Return the room data in the format expected by the frontend
        res.status(201).json({
            message: 'Room created successfully',
            room: {
                room_id: newRoom.room_id,
                room_name: newRoom.room_name,
                subject_id: newRoom.subject_id,
                is_public: newRoom.is_public,
                created_by: newRoom.created_by,
                creator_full_name: newRoom.creator_full_name,
                created_at: newRoom.created_at
            }
        });
    } catch (error) {
        console.error('Error creating room:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Get details for a specific room
export const getRoomById = async (req: Request, res: Response) => {
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        const room = await pool.query(
            `SELECT r.*, s.name as subject_name, u.full_name as creator_name,
                    p.user_id as participant_user_id, p.full_name as participant_full_name
             FROM rooms r
             LEFT JOIN subjects s ON r.subject_id = s.subject_id
             LEFT JOIN users u ON r.created_by = u.user_id
             LEFT JOIN room_participants rp ON r.room_id = rp.room_id
             LEFT JOIN users p ON rp.user_id = p.user_id
             WHERE r.room_id = $1`,
            [roomId]
        );

        if (room.rows.length === 0) {
            return res.status(404).json({ message: 'Room not found.' });
        }

        res.status(200).json(room.rows[0]);
    } catch (error) {
        console.error(`Error fetching room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Join a room
export const joinRoom = async (req: Request, res: Response) => {
    const { roomId } = req.params;
    const userId = req.user!.user_id;

    try {
        // Check if room exists and is public
        const roomResult = await pool.query(
            'SELECT * FROM rooms WHERE room_id = $1 AND is_public = true',
            [roomId]
        );

        if (roomResult.rows.length === 0) {
            return res.status(404).json({ message: 'Room not found or not public' });
        }

        // Check if user is already a participant
        const participantResult = await pool.query(
            'SELECT * FROM room_participants WHERE room_id = $1 AND user_id = $2',
            [roomId, userId]
        );

        // If user is already a participant, return success
        if (participantResult.rows.length > 0) {
            return res.status(200).json({ 
                message: 'Already a participant in this room',
                isAlreadyParticipant: true 
            });
        }

        // Add user as participant
        await pool.query(
            `INSERT INTO room_participants (room_id, user_id)
             VALUES ($1, $2)`,
            [roomId, userId]
        );

        res.status(200).json({ 
            message: 'Successfully joined room',
            isAlreadyParticipant: false 
        });
    } catch (error) {
        console.error('Error joining room:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Get messages for a specific room
export const getMessagesForRoom = async (req: Request, res: Response) => {
    const userId = req.user!.user_id;
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        const messages = await pool.query(
            `SELECT m.*, u.full_name as sender_full_name
             FROM messages m
             LEFT JOIN users u ON m.sender_id = u.user_id
             WHERE m.room_id = $1
             ORDER BY m.sent_at ASC`,
            [roomId]
        );

        res.status(200).json(messages.rows);
    } catch (error) {
        console.error(`Error fetching messages for room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Handle file upload for a room
export const uploadFile = async (req: Request, res: Response) => {
    const userId = req.user!.user_id;
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    if (!req.file) {
        return res.status(400).json({ message: 'No file uploaded.' });
    }

    try {
        const file = req.file;
        const fileUrl = `/uploads/${file.filename}`;
        const messageType = file.mimetype.startsWith('image/') ? 'image' : 'pdf';

        // Save message reference to database
        const messageResult = await pool.query(
            `INSERT INTO messages (room_id, sender_id, message_type, message_text, file_url)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [roomId, userId, messageType, file.originalname, fileUrl]
        );

        const newMessage = messageResult.rows[0];

        // Get sender's full name
        const userResult = await pool.query(
            'SELECT full_name FROM users WHERE user_id = $1',
            [userId]
        );
        const senderFullName = userResult.rows[0]?.full_name;

        // Broadcast the new file message via WebSocket
        const io = req.app.get('io') as SocketIOServer;
        io.to(`room_${roomId}`).emit('newMessage', {
            ...newMessage,
            sender_full_name: senderFullName
        });

        res.status(201).json({ 
            message: 'File uploaded successfully', 
            messageData: {
                ...newMessage,
                sender_full_name: senderFullName
            }
        });
    } catch (error) {
        console.error(`Error uploading file for room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
