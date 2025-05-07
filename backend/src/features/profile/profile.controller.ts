import { Request, Response } from 'express';
import prisma from '../../db';

/**
 * Get user profile
 * @route GET /api/profile
 */
export const getUserProfile = async (req: Request, res: Response) => {
    try {
        // TODO: Get user ID from authenticated session when auth middleware is implemented
        // Auth middleware should add the user object to the request
        // For now, we'll use a user ID from the request query, body, or user object if available
        const userId = parseInt(req.query.userId as string) || parseInt(req.body.userId as string) || 1;
        
        // NOTE: When auth middleware is properly implemented, this should be:
        // const userId = req.user.user_id;

        // First get the user to ensure it exists
        const user = await prisma.user.findUnique({
            where: { user_id: userId },
            include: {
                profile: true // Include the profile relation
            }
        });

        if (!user) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }

        // If user exists but profile doesn't, create an empty profile
        if (!user.profile) {
            // Create a new profile for the user
            await prisma.userProfile.create({
                data: {
                    user_id: userId,
                    bio: null,
                    profile_picture: null
                }
            });
            
            // Fetch the user again with the newly created profile
            const updatedUser = await prisma.user.findUnique({
                where: { user_id: userId },
                include: {
                    profile: true
                }
            });
            
            if (!updatedUser || !updatedUser.profile) {
                return res.status(500).json({ message: 'Profil oluşturulurken bir hata oluştu' });
            }
            
            user.profile = updatedUser.profile;
        }

        // Format the response to match the frontend expectations
        const profileResponse = {
            username: user.full_name, // User model has full_name, not username
            university: user.university,
            department: user.department,
            profilePictureUrl: user.profile.profile_picture,
            bio: user.profile.bio
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
        // TODO: Get user ID from authenticated session when auth middleware is implemented
        // Auth middleware should add the user object to the request
        // For now, we'll use a user ID from the request query, body, or user object if available
        const userId = parseInt(req.query.userId as string) || parseInt(req.body.userId as string) || 1;
        
        // NOTE: When auth middleware is properly implemented, this should be:
        // const userId = req.user.user_id;
        
        const { username, university, department, profilePictureUrl, bio } = req.body;

        // First check if user exists
        const user = await prisma.user.findUnique({
            where: { user_id: userId },
            include: {
                profile: true
            }
        });

        if (!user) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }

        // If profile doesn't exist, create it
        if (!user.profile) {
            await prisma.userProfile.create({
                data: {
                    user_id: userId,
                    profile_picture: profilePictureUrl || null,
                    bio: bio || null
                }
            });
        } else {
            // Update existing profile
            await prisma.userProfile.update({
                where: { user_id: userId },
                data: {
                    profile_picture: profilePictureUrl !== undefined ? profilePictureUrl : user.profile.profile_picture,
                    bio: bio !== undefined ? bio : user.profile.bio
                }
            });
        }

        // Update user fields if provided
        if (username || university || department) {
            await prisma.user.update({
                where: { user_id: userId },
                data: { 
                    full_name: username || undefined, // Update full_name instead of username
                    university: university || undefined,
                    department: department || undefined
                }
            });
        }

        res.status(200).json({ message: 'Profil başarıyla güncellendi' });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Profil güncellenirken bir hata oluştu' });
    }
};