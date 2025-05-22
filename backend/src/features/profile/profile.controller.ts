import { Request, Response } from 'express';
import pool, { query as executeQuery } from '../../db'; // Updated import

/**
 * Get user profile
 * @route GET /api/profile
 */
export const getUserProfile = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.user_id;

        // Fetch user and their profile using raw SQL
        let userResult = await executeQuery(
            `SELECT u.user_id, u.full_name, u.email, u.university, u.department, 
                    up.profile_id, up.bio, up.profile_picture
             FROM users u
             LEFT JOIN user_profiles up ON u.user_id = up.user_id
             WHERE u.user_id = $1`,
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }

        let user = userResult.rows[0];

        // If user exists but profile doesn't (profile_id is null), create an empty profile
        if (!user.profile_id) {
            await executeQuery(
                'INSERT INTO user_profiles (user_id, bio, profile_picture) VALUES ($1, $2, $3)',
                [userId, null, null]
            );
            
            // Fetch the user again with the newly created profile
            const updatedUserResult = await executeQuery(
                `SELECT u.user_id, u.full_name, u.email, u.university, u.department, 
                        up.profile_id, up.bio, up.profile_picture
                 FROM users u
                 LEFT JOIN user_profiles up ON u.user_id = up.user_id
                 WHERE u.user_id = $1`,
                [userId]
            );
            
            if (updatedUserResult.rows.length === 0 || !updatedUserResult.rows[0].profile_id) {
                return res.status(500).json({ message: 'Profil oluşturulurken bir hata oluştu' });
            }
            user = updatedUserResult.rows[0];
        }

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
        res.status(500).json({ message: 'Profil bilgileri alınırken bir hata oluştu' });
    }
};

/**
 * Update user profile
 * @route PUT /api/profile
 */
export const updateUserProfile = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.user_id;
        const { username, university, department, profilePictureUrl, bio } = req.body;

        // Check if user exists
        const userResult = await executeQuery('SELECT * FROM users WHERE user_id = $1', [userId]);

        if (userResult.rows.length === 0) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }

        // Check if profile exists
        let profileResult = await executeQuery('SELECT * FROM user_profiles WHERE user_id = $1', [userId]);

        if (profileResult.rows.length === 0) {
            // Create new profile
            await executeQuery(
                'INSERT INTO user_profiles (user_id, profile_picture, bio) VALUES ($1, $2, $3)',
                [userId, profilePictureUrl || null, bio || null]
            );
        } else {
            // Update existing profile
            const currentProfile = profileResult.rows[0];
            const newProfilePicture = profilePictureUrl !== undefined ? profilePictureUrl : currentProfile.profile_picture;
            const newBio = bio !== undefined ? bio : currentProfile.bio;

            if (profilePictureUrl !== undefined || bio !== undefined) { // Only update if new values are provided
                await executeQuery(
                    'UPDATE user_profiles SET profile_picture = $1, bio = $2 WHERE user_id = $3',
                    [newProfilePicture, newBio, userId]
                );
            }
        }

        // Update user fields if provided
        const userUpdates: string[] = [];
        const userValues: any[] = [];
        let paramCount = 1;

        if (username !== undefined) {
            userUpdates.push(`full_name = $${paramCount++}`);
            userValues.push(username);
        }
        if (university !== undefined) {
            userUpdates.push(`university = $${paramCount++}`);
            userValues.push(university);
        }
        if (department !== undefined) {
            userUpdates.push(`department = $${paramCount++}`);
            userValues.push(department);
        }

        if (userUpdates.length > 0) {
            userValues.push(userId); // Add userId for the WHERE clause
            const updateUserQuery = `UPDATE users SET ${userUpdates.join(', ')} WHERE user_id = $${paramCount}`;
            await executeQuery(updateUserQuery, userValues);
        }

        res.status(200).json({ message: 'Profil başarıyla güncellendi' });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Profil güncellenirken bir hata oluştu' });
    }
};