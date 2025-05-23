import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import pool from '../../db';

// JWT secret key - Bu değer normalde environment variable'dan alınmalıdır
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Request tipini genişletiyoruz, böylece user özelliğini ekleyebiliriz
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

/**
 * JWT token doğrulama middleware'i
 * Bu middleware, gelen isteklerdeki JWT token'ı doğrular ve kullanıcı bilgilerini request nesnesine ekler
 */
export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN formatından token'ı ayıklıyoruz

        if (!token) {
            return res.status(401).json({ message: 'Yetkilendirme tokenı bulunamadı' });
        }

        // Token'ı doğrula
        const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };

        // Kullanıcıyı veritabanından bul (raw SQL)
        const userResult = await pool.query(
            'SELECT user_id, email, full_name FROM users WHERE user_id = $1',
            [decoded.userId]
        );
        const user = userResult.rows[0];

        if (!user) {
            return res.status(401).json({ message: 'Geçersiz kullanıcı' });
        }

        // Kullanıcı bilgilerini request nesnesine ekle
        req.user = user;
        next();
    } catch (error) {
        if (error instanceof jwt.JsonWebTokenError) {
            return res.status(401).json({ message: 'Geçersiz token' });
        }
        console.error('Auth middleware error:', error);
        return res.status(500).json({ message: 'Kimlik doğrulama sırasında bir hata oluştu' });
    }
};