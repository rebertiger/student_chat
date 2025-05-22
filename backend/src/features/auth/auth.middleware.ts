import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import pool, { query as executeQuery } from '../../db'; // Updated import

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

declare global {
    namespace Express {
        interface Request {
            user?: {
                user_id: number;
                email: string;
                full_name: string;
            };
        }
    }
}

export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({ message: 'Yetkilendirme tokenı bulunamadı' });
        }

        const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };

        const userResult = await executeQuery(
            'SELECT user_id, email, full_name FROM users WHERE user_id = $1',
            [decoded.userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(401).json({ message: 'Geçersiz kullanıcı' });
        }

        req.user = userResult.rows[0];
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        if (error instanceof jwt.JsonWebTokenError) {
            return res.status(401).json({ message: 'Geçersiz token' });
        }
        return res.status(500).json({ message: 'Yetkilendirme sırasında bir hata oluştu' });
    }
};