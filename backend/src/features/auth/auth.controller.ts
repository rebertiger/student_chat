import { Request, Response } from 'express';
import pool from '../../db';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const SALT_ROUNDS = 10; // Standard salt rounds for bcrypt
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key'; // JWT secret key - Bu değer normalde environment variable'dan alınmalıdır

export const register = async (req: Request, res: Response) => {
    const { email, password, full_name, university, department } = req.body;

    // Basic validation
    if (!email || !password || !full_name) {
        return res.status(400).json({ message: 'Email, password, and full name are required.' });
    }

    try {
        // Check if user already exists
        const existingUserResult = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );

        if (existingUserResult.rows.length > 0) {
            return res.status(409).json({ message: 'User with this email already exists.' });
        }

        // Hash password
        const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

        // Create user
        const newUserResult = await pool.query(
            `INSERT INTO users (email, password_hash, full_name, university, department)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING user_id, email, full_name, university, department, created_at`,
            [email, password_hash, full_name, university, department]
        );

        const newUser = newUserResult.rows[0];

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
        // Find user by email
        const userResult = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );

        const user = userResult.rows[0];

        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }

        // Compare password with hash
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }

        // Login successful - create and return JWT token
        const token = jwt.sign(
            { 
                userId: user.user_id,
                email: user.email,
                full_name: user.full_name
            }, 
            JWT_SECRET, 
            { expiresIn: '24h' }
        );
        
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
