import express from 'express';
import { Request, Response } from 'express';
import pool, { query as executeQuery } from '../../db'; // Updated import

const router = express.Router();

/**
 * POST /api/reports/message
 * Report a message
 */
router.post('/message', async (req: Request, res: Response) => {
  try {
    const { messageId, reason } = req.body;
    const reportedByUserId = req.user?.user_id; // Assuming authenticateToken middleware is used

    if (!messageId) {
      return res.status(400).json({ message: 'Message ID is required' });
    }

    const messageIdNum = typeof messageId === 'string' ? parseInt(messageId, 10) : messageId;
    if (isNaN(messageIdNum)) {
        return res.status(400).json({ message: 'Invalid Message ID format' });
    }

    // Check if the message exists
    const messageExistsResult = await executeQuery('SELECT 1 FROM messages WHERE message_id = $1', [messageIdNum]);

    if (messageExistsResult.rows.length === 0) {
      return res.status(404).json({ message: 'Message not found' });
    }

    // Create the report
    const reportResult = await executeQuery(
      'INSERT INTO reports (message_id, reported_by, reason) VALUES ($1, $2, $3) RETURNING *',
      [messageIdNum, reportedByUserId || null, reason || null]
    );

    return res.status(201).json({
      message: 'Message reported successfully',
      report: reportResult.rows[0]
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
router.get('/', async (req: Request, res: Response) => {
  // Add admin check if necessary: if (!req.user || !req.user.isAdmin) return res.status(403).json(...);
  try {
    const reportsResult = await executeQuery(
      `SELECT r.report_id, r.message_id, r.reported_by, r.reason, r.reported_at,
              m.message_text, m.message_type, m.file_url, m.sent_at AS message_sent_at,
              u.user_id AS reporter_user_id, u.full_name AS reporter_full_name, u.email AS reporter_email
       FROM reports r
       JOIN messages m ON r.message_id = m.message_id
       LEFT JOIN users u ON r.reported_by = u.user_id
       ORDER BY r.reported_at DESC`
    );

    const reports = reportsResult.rows.map(row => ({
      report_id: row.report_id,
      message_id: row.message_id,
      reported_by: row.reported_by,
      reason: row.reason,
      reported_at: row.reported_at,
      message: {
        message_id: row.message_id, // Repeating for consistency with Prisma output
        message_text: row.message_text,
        message_type: row.message_type,
        file_url: row.file_url,
        sent_at: row.message_sent_at
      },
      reporter: row.reporter_user_id ? {
        user_id: row.reporter_user_id,
        full_name: row.reporter_full_name,
        email: row.reporter_email
      } : null
    }));
    
    return res.status(200).json(reports);
  } catch (error) {
    console.error('Error fetching reports:', error);
    return res.status(500).json({ message: 'Failed to fetch reports', error: String(error) });
  }
});

export default router;