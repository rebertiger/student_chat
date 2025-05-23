import { Request, Response } from 'express';
import pool from '../../db';

/**
 * Get user profile
 * @route GET /api/profile
 */
export const getUserProfile = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.user_id;

        // Get user with profile
        const userResult = await pool.query(
            `SELECT u.*, up.*
             FROM users u
             LEFT JOIN user_profiles up ON u.user_id = up.user_id
             WHERE u.user_id = $1`,
            [userId]
        );

        const user = userResult.rows[0];

        if (!user) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }

        // If user exists but profile doesn't, create an empty profile
        if (!user.profile_id) {
            const newProfileResult = await pool.query(
                `INSERT INTO user_profiles (user_id, bio, profile_picture)
                 VALUES ($1, NULL, NULL)
                 RETURNING *`,
                [userId]
            );

            if (!newProfileResult.rows[0]) {
                return res.status(500).json({ message: 'Profil oluşturulurken bir hata oluştu' });
            }

            user.profile_id = newProfileResult.rows[0].profile_id;
            user.bio = null;
            user.profile_picture = null;
        }

        // Format the response to match the frontend expectations
        const profileResponse = {
            username: user.full_name,
            university: user.university,
            department: user.department,
            profilePictureUrl: user.profile_picture,
            bio: user.bio
        };

        res.status(200).json(profileResponse);
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

/**
 * Update user profile
 * @route PUT /api/profile
 */
export const updateUserProfile = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.user_id;
        const { username, university, department, bio, profilePictureUrl } = req.body;

        // Update users table for full_name, university, department
        await pool.query(
            `UPDATE users SET full_name = $1, university = $2, department = $3 WHERE user_id = $4`,
            [username, university, department, userId]
        );

        // Update or insert profile
        const result = await pool.query(
            `INSERT INTO user_profiles (user_id, bio, profile_picture)
             VALUES ($1, $2, $3)
             ON CONFLICT (user_id) DO UPDATE
             SET bio = $2, profile_picture = $3
             RETURNING *`,
            [userId, bio, profilePictureUrl]
        );

        if (!result.rows[0]) {
            return res.status(500).json({ message: 'Profil güncellenirken bir hata oluştu' });
        }

        res.status(200).json({ message: 'Profil başarıyla güncellendi' });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};