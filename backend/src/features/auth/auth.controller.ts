import { Request, Response } from 'express';
import pool, { query as executeQuery } from '../../db'; // Updated import
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const SALT_ROUNDS = 10;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

export const register = async (req: Request, res: Response) => {
    const { email, password, full_name, university, department } = req.body;

    if (!email || !password || !full_name) {
        return res.status(400).json({ message: 'Email, password, and full name are required.' });
    }

    try {
        const existingUserResult = await executeQuery('SELECT * FROM users WHERE email = $1', [email]);

        if (existingUserResult.rows.length > 0) {
            return res.status(409).json({ message: 'User with this email already exists.' });
        }

        const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

        const newUserResult = await executeQuery(
            'INSERT INTO users (email, password_hash, full_name, university, department) VALUES ($1, $2, $3, $4, $5) RETURNING user_id, email, full_name, university, department, created_at',
            [email, password_hash, full_name, university, department]
        );

        const newUser = newUserResult.rows[0];

        // Optional: Create a profile entry. This can be done here or handled by profile controller.
        // await executeQuery('INSERT INTO user_profiles (user_id) VALUES ($1)', [newUser.user_id]);

        res.status(201).json({ message: 'User registered successfully', user: newUser });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Internal server error during registration.' });
    }
};

export const login = async (req: Request, res: Response) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required.' });
    }

    try {
        const userResult = await executeQuery('SELECT * FROM users WHERE email = $1', [email]);

        if (userResult.rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const user = userResult.rows[0];
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const token = jwt.sign({ userId: user.user_id }, JWT_SECRET, { expiresIn: '24h' });
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { password_hash, ...userData } = user;
        res.status(200).json({
            message: 'Giriş başarılı',
            user: userData,
            token: token
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Internal server error during login.' });
    }
};
