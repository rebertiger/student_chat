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
        const messageExists = yield db_1.default.message.findUnique({
            where: { message_id: messageIdNum }
        });
        if (!messageExists) {
            return res.status(404).json({ message: 'Message not found' });
        }
        // Create the report
        const report = yield db_1.default.report.create({
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
        const reports = yield db_1.default.report.findMany({
            include: {
                message: true,
                reporter: {
                    select: { user_id: true, full_name: true, email: true }
                }
            }
        });
        return res.status(200).json(reports);
    }
    catch (error) {
        console.error('Error fetching reports:', error);
        return res.status(500).json({ message: 'Failed to fetch reports', error: String(error) });
    }
}));
exports.default = router;
