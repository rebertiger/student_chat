"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const db_1 = __importDefault(require("../../db"));
const router = express_1.default.Router();
/**
 * POST /api/reports/message
 * Report a message
 */
router.post('/message', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { messageId, reportedBy, reason } = req.body;
        // Basic validation
        if (!messageId) {
            return res.status(400).json({ message: 'Message ID is required' });
        }
        // Convert messageId to number if it's a string
        const messageIdNum = typeof messageId === 'string' ? parseInt(messageId, 10) : messageId;
        // Check if the message exists
        const messageExistsResult = yield db_1.default.query('SELECT * FROM messages WHERE message_id = $1', [messageIdNum]);
        const messageExists = messageExistsResult.rows.length > 0 ? messageExistsResult.rows[0] : null;
        if (!messageExists) {
            return res.status(404).json({ message: 'Message not found' });
        }
        // Create the report
        const reportResult = yield db_1.default.query(
            'INSERT INTO reports (message_id, reported_by, reason) VALUES ($1, $2, $3) RETURNING *',
            [messageIdNum, reportedBy ? parseInt(reportedBy, 10) : null, reason || null]
        );
        const report = reportResult.rows[0];
        return res.status(201).json({
            message: 'Message reported successfully',
            report
        });
    }
    catch (error) {
        console.error('Error reporting message:', error);
        return res.status(500).json({ message: 'Failed to report message', error: String(error) });
    }
}));
/**
 * GET /api/reports
 * Get all reports (could be restricted to admins in a real app)
 */
router.get('/', (_req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const reportsResult = yield db_1.default.query(
            'SELECT r.*, m.message_id AS message_message_id, m.room_id AS message_room_id, m.sender_id AS message_sender_id, m.message_text AS message_message_text, m.message_type AS message_message_type, m.file_url AS message_file_url, m.sent_at AS message_sent_at, m.is_edited AS message_is_edited, u.user_id AS reporter_user_id, u.full_name AS reporter_full_name, u.email AS reporter_email FROM reports r LEFT JOIN messages m ON r.message_id = m.message_id LEFT JOIN users u ON r.reported_by = u.user_id'
        );
        // Map the flat result back to a nested structure similar to Prisma's include
        const reports = reportsResult.rows.map(row => ({
            report_id: row.report_id,
            message_id: row.message_id,
            reported_by: row.reported_by,
            reason: row.reason,
            created_at: row.created_at,
            message: row.message_message_id ? {
                message_id: row.message_message_id,
                room_id: row.message_room_id,
                sender_id: row.message_sender_id,
                message_text: row.message_message_text,
                message_type: row.message_message_type,
                file_url: row.message_file_url,
                sent_at: row.message_sent_at,
                is_edited: row.message_is_edited,
            } : null,
            reporter: row.reporter_user_id ? {
                user_id: row.reporter_user_id,
                full_name: row.reporter_full_name,
                email: row.reporter_email,
            } : null,
        }));
        return res.status(200).json(reports);
    }
    catch (error) {
        console.error('Error fetching reports:', error);
        return res.status(500).json({ message: 'Failed to fetch reports', error: String(error) });
    }
}));
exports.default = router;
