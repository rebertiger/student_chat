import { Request, Response } from 'express';
import pool from '../../db';

export const getMessages = async (req: Request, res: Response) => {
    const { roomId } = req.params;

    try {
        const result = await pool.query(
            `SELECT m.*, u.full_name as sender_full_name
             FROM messages m
             LEFT JOIN users u ON m.sender_id = u.user_id
             WHERE m.room_id = $1
             ORDER BY m.sent_at ASC`,
            [roomId]
        );

        // Get total message count using the database function
        const countResult = await pool.query(
            `SELECT count_room_messages($1) as total_messages`,
            [roomId]
        );

        const totalMessages = parseInt(countResult.rows[0].total_messages, 10);

        res.status(200).json({
            messages: result.rows,
            totalMessages: totalMessages
        });
    } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

export const createMessage = async (req: Request, res: Response) => {
    const { roomId } = req.params;
    const { messageText, messageType = 'text', fileUrl } = req.body;
    const userId = req.user!.user_id;

    try {
        // Check if user is a participant in the room
        const participantResult = await pool.query(
            'SELECT * FROM room_participants WHERE room_id = $1 AND user_id = $2',
            [roomId, userId]
        );

        if (participantResult.rows.length === 0) {
            return res.status(403).json({ message: 'You are not a participant in this room' });
        }

        // Create message
        const result = await pool.query(
            `INSERT INTO messages (room_id, sender_id, message_type, message_text, file_url)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [roomId, userId, messageType, messageText, fileUrl]
        );

        const newMessage = result.rows[0];

        // Get sender's full name
        const userResult = await pool.query(
            'SELECT full_name FROM users WHERE user_id = $1',
            [userId]
        );

        const sender = userResult.rows[0];
        newMessage.sender_full_name = sender.full_name;

        res.status(201).json(newMessage);
    } catch (error) {
        console.error('Error creating message:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

export const reportMessage = async (req: Request, res: Response) => {
    const { messageId } = req.params;
    const { reason } = req.body;
    const userId = req.user!.user_id;

    try {
        // Check if message exists
        const messageResult = await pool.query(
            'SELECT * FROM messages WHERE message_id = $1',
            [messageId]
        );

        if (messageResult.rows.length === 0) {
            return res.status(404).json({ message: 'Message not found' });
        }

        // Create report
        const result = await pool.query(
            `INSERT INTO reports (message_id, reported_by, reason)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [messageId, userId, reason]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error reporting message:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Get total message count for a room
export const getMessageCount = async (req: Request, res: Response) => {
    const { roomId } = req.params;

    try {
        const result = await pool.query(
            `SELECT COUNT(*) as total_messages
             FROM messages
             WHERE room_id = $1`,
            [roomId]
        );

        const totalMessages = parseInt(result.rows[0].total_messages, 10);

        res.status(200).json({ totalMessages });
    } catch (error) {
        console.error('Error fetching message count:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};