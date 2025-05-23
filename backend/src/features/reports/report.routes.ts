import express from 'express';
import { Request, Response } from 'express';
import pool from '../../db';

const router = express.Router();

/**
 * POST /api/reports/message
 * Report a message
 */
router.post('/message', async (req: Request, res: Response) => {
  try {
    const { messageId, reportedBy, reason } = req.body;

    // Basic validation
    if (!messageId) {
      return res.status(400).json({ message: 'Message ID is required' });
    }

    // Convert messageId to number if it's a string
    const messageIdNum = typeof messageId === 'string' ? parseInt(messageId, 10) : messageId;

    // Check if the message exists
    const messageResult = await pool.query(
      'SELECT * FROM messages WHERE message_id = $1',
      [messageIdNum]
    );
    const messageExists = messageResult.rows[0];

    if (!messageExists) {
      return res.status(404).json({ message: 'Message not found' });
    }

    // Create the report
    const reportResult = await pool.query(
      `INSERT INTO reports (message_id, reported_by, reason)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [messageIdNum, reportedBy ? parseInt(reportedBy, 10) : null, reason || null]
    );
    const report = reportResult.rows[0];

    return res.status(201).json({
      message: 'Message reported successfully',
      report
    });
  } catch (error) {
    console.error('Error reporting message:', error);
    return res.status(500).json({ message: 'Failed to report message', error: String(error) });
  }
});

/**
 * GET /api/reports
 * Get all reports (could be restricted to admins in a real app)
 */
router.get('/', async (_req: Request, res: Response) => {
  try {
    const reportsResult = await pool.query(
      `SELECT r.*, 
              m.message_text, m.message_type, m.file_url, m.room_id, m.sender_id,
              u.user_id as reporter_user_id, u.full_name as reporter_full_name, u.email as reporter_email
         FROM reports r
    LEFT JOIN messages m ON r.message_id = m.message_id
    LEFT JOIN users u ON r.reported_by = u.user_id
    ORDER BY r.created_at DESC`
    );
    const reports = reportsResult.rows;
    return res.status(200).json(reports);
  } catch (error) {
    console.error('Error fetching reports:', error);
    return res.status(500).json({ message: 'Failed to fetch reports', error: String(error) });
  }
});

export default router; 