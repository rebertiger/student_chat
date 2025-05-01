import { Request, Response } from 'express';
import prisma from '../../db';
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10; // Standard salt rounds for bcrypt

export const register = async (req: Request, res: Response) => {
    const { email, password, full_name, university, department } = req.body;

    // Basic validation
    if (!email || !password || !full_name) {
        return res.status(400).json({ message: 'Email, password, and full name are required.' });
    }

    try {
        // Check if user already exists
        const existingUser = await prisma.user.findUnique({
            where: { email },
        });

        if (existingUser) {
            return res.status(409).json({ message: 'User with this email already exists.' });
        }

        // Hash password
        const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

        // Create user
        const newUser = await prisma.user.create({
            data: {
                email,
                password_hash,
                full_name,
                university, // Optional
                department, // Optional
                // Prisma automatically adds created_at
            },
            // Select only non-sensitive fields to return
            select: {
                user_id: true,
                email: true,
                full_name: true,
                university: true,
                department: true,
                created_at: true
            }
        });

        // Optionally create a profile entry (can be done later or upon first profile edit)
        // await prisma.userProfile.create({ data: { user_id: newUser.user_id } });

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
        const user = await prisma.user.findUnique({
            where: { email },
        });

        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }

        // Compare password with hash
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }

        // Login successful - return user data (excluding password hash)
        // In a real app, you'd typically issue a token (JWT) here
        const { password_hash, ...userData } = user;
        res.status(200).json({ message: 'Login successful', user: userData });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Internal server error during login.' });
    }
};
