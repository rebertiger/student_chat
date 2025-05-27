import { Request, Response } from 'express';
import pool from '../../db';

// List all subjects
export const getAllSubjects = async (_req: Request, res: Response) => {
    try {
        const result = await pool.query('SELECT * FROM subjects ORDER BY name ASC');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching subjects:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Add a new subject (optional, for admin use)
export const addSubject = async (req: Request, res: Response) => {
    const { name, description } = req.body;
    if (!name) return res.status(400).json({ message: 'Subject name is required' });
    try {
        const result = await pool.query(
            'INSERT INTO subjects (name, description) VALUES ($1, $2) RETURNING *',
            [name, description || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error adding subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// List current user's subjects
export const getUserSubjects = async (req: Request, res: Response) => {
    const userId = req.user!.user_id;
    try {
        const result = await pool.query(
            `SELECT s.* FROM user_subjects us
             JOIN subjects s ON us.subject_id = s.subject_id
             WHERE us.user_id = $1
             ORDER BY s.name ASC`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching user subjects:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Add a subject to current user
export const addUserSubject = async (req: Request, res: Response) => {
    const userId = req.user!.user_id;
    const { subjectId } = req.body;
    if (!subjectId) return res.status(400).json({ message: 'Subject ID is required' });
    try {
        await pool.query(
            'INSERT INTO user_subjects (user_id, subject_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, subjectId]
        );
        res.status(201).json({ message: 'Subject added to user' });
    } catch (error) {
        console.error('Error adding user subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Remove a subject from current user
export const removeUserSubject = async (req: Request, res: Response) => {
    const userId = req.user!.user_id;
    const subjectId = parseInt(req.params.subjectId, 10);
    if (isNaN(subjectId)) return res.status(400).json({ message: 'Invalid subject ID' });
    try {
        await pool.query(
            'DELETE FROM user_subjects WHERE user_id = $1 AND subject_id = $2',
            [userId, subjectId]
        );
        res.status(200).json({ message: 'Subject removed from user' });
    } catch (error) {
        console.error('Error removing user subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
}; 