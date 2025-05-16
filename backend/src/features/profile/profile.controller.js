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
        const user = yield db_1.default.user.findUnique({
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
            yield db_1.default.userProfile.create({
                data: {
                    user_id: userId,
                    bio: null,
                    profile_picture: null
                }
            });
            // Fetch the user again with the newly created profile
            const updatedUser = yield db_1.default.user.findUnique({
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
        const user = yield db_1.default.user.findUnique({
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
            yield db_1.default.userProfile.create({
                data: {
                    user_id: userId,
                    profile_picture: profilePictureUrl || null,
                    bio: bio || null
                }
            });
        }
        else {
            // Update existing profile
            yield db_1.default.userProfile.update({
                where: { user_id: userId },
                data: {
                    profile_picture: profilePictureUrl !== undefined ? profilePictureUrl : user.profile.profile_picture,
                    bio: bio !== undefined ? bio : user.profile.bio
                }
            });
        }
        // Update user fields if provided
        if (username || university || department) {
            yield db_1.default.user.update({
                where: { user_id: userId },
                data: {
                    full_name: username || undefined, // Update full_name instead of username
                    university: university || undefined,
                    department: department || undefined
                }
            });
        }
        res.status(200).json({ message: 'Profil başarıyla güncellendi' });
    }
    catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Profil güncellenirken bir hata oluştu' });
    }
});
exports.updateUserProfile = updateUserProfile;
