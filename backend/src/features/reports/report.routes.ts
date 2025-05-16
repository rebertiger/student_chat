import express from 'express';
import { Request, Response } from 'express';
import prisma from '../../db';

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
    const messageExists = await prisma.message.findUnique({
      where: { message_id: messageIdNum }
    });

    if (!messageExists) {
      return res.status(404).json({ message: 'Message not found' });
    }

    // Create the report
    const report = await prisma.report.create({
      data: {
        message_id: messageIdNum,
        reported_by: reportedBy ? parseInt(reportedBy, 10) : null,
        reason: reason || null
      }
    });

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
    const reports = await prisma.report.findMany({
      include: {
        message: true,
        reporter: {
          select: { user_id: true, full_name: true, email: true }
        }
      }
    });
    
    return res.status(200).json(reports);
  } catch (error) {
    console.error('Error fetching reports:', error);
    return res.status(500).json({ message: 'Failed to fetch reports', error: String(error) });
  }
});

export default router; 