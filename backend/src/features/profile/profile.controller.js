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
exports.updateUserProfile = exports.getUserProfile = void 0;
const db_1 = __importDefault(require("../../db"));
/**
 * Get user profile
 * @route GET /api/profile
 */
const getUserProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // Auth middleware'den gelen kullanıcı bilgilerini kullan
        const userId = req.user.user_id;
        // First get the user to ensure it exists
        const userResult = yield db_1.default.query('SELECT u.*, up.bio, up.profile_picture FROM users u LEFT JOIN user_profiles up ON u.user_id = up.user_id WHERE u.user_id = $1', [userId]);
        const user = userResult.rows.length > 0 ? userResult.rows[0] : null;

        // Map profile data if exists
        if (user) {
            user.profile = user.bio !== undefined || user.profile_picture !== undefined ? {
                user_id: user.user_id,
                bio: user.bio,
                profile_picture: user.profile_picture
            } : null;
            // Clean up temporary fields
            delete user.bio;
            delete user.profile_picture;
        }
        if (!user) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }
        // If user exists but profile doesn't, create an empty profile
        if (!user.profile) {
            // Create a new profile for the user
            yield db_1.default.query('INSERT INTO user_profiles (user_id, bio, profile_picture) VALUES ($1, NULL, NULL)', [userId]);
            // Fetch the user again with the newly created profile
            const updatedUserResult = yield db_1.default.query('SELECT u.*, up.bio, up.profile_picture FROM users u LEFT JOIN user_profiles up ON u.user_id = up.user_id WHERE u.user_id = $1', [userId]);
            const updatedUser = updatedUserResult.rows.length > 0 ? updatedUserResult.rows[0] : null;

            // Map profile data if exists
            if (updatedUser) {
                updatedUser.profile = updatedUser.bio !== undefined || updatedUser.profile_picture !== undefined ? {
                    user_id: updatedUser.user_id,
                    bio: updatedUser.bio,
                    profile_picture: updatedUser.profile_picture
                } : null;
                // Clean up temporary fields
                delete updatedUser.bio;
                delete updatedUser.profile_picture;
            }
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
    }
    catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Profil bilgileri alınırken bir hata oluştu' });
    }
});
exports.getUserProfile = getUserProfile;
/**
 * Update user profile
 * @route PUT /api/profile
 */
const updateUserProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // Auth middleware'den gelen kullanıcı bilgilerini kullan
        const userId = req.user.user_id;
        const { username, university, department, profilePictureUrl, bio } = req.body;
        // First check if user exists
        const userResult = yield db_1.default.query('SELECT u.*, up.bio, up.profile_picture FROM users u LEFT JOIN user_profiles up ON u.user_id = up.user_id WHERE u.user_id = $1', [userId]);
        const user = userResult.rows.length > 0 ? userResult.rows[0] : null;

        // Map profile data if exists
        if (user) {
            user.profile = user.bio !== undefined || user.profile_picture !== undefined ? {
                user_id: user.user_id,
                bio: user.bio,
                profile_picture: user.profile_picture
            } : null;
            // Clean up temporary fields
            delete user.bio;
            delete user.profile_picture;
        }
        if (!user) {
            return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
        }
        // If profile doesn't exist, create it
        if (!user.profile) {
            yield db_1.default.query('INSERT INTO user_profiles (user_id, profile_picture, bio) VALUES ($1, $2, $3)', [userId, profilePictureUrl || null, bio || null]);
        }
        else {
            // Update existing profile
            yield db_1.default.query('UPDATE user_profiles SET profile_picture = COALESCE($2, profile_picture), bio = COALESCE($3, bio) WHERE user_id = $1', [userId, profilePictureUrl, bio]);
        }
        // Update user fields if provided
        if (username || university || department) {
            const updateFields = [];
            const updateValues = [];
            let paramIndex = 1;

            if (username !== undefined) { updateFields.push(`full_name = $${paramIndex++}`); updateValues.push(username); }
            if (university !== undefined) { updateFields.push(`university = $${paramIndex++}`); updateValues.push(university); }
            if (department !== undefined) { updateFields.push(`department = $${paramIndex++}`); updateValues.push(department); }

            if (updateFields.length > 0) {
                const updateQuery = `UPDATE users SET ${updateFields.join(', ')} WHERE user_id = $${paramIndex}`; // Last param is userId
                updateValues.push(userId);
                yield db_1.default.query(updateQuery, updateValues);
            }
        }
        res.status(200).json({ message: 'Profil başarıyla güncellendi' });
    }
    catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Profil güncellenirken bir hata oluştu' });
    }
});
exports.updateUserProfile = updateUserProfile;
