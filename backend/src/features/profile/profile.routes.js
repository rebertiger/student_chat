"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const profile_controller_1 = require("./profile.controller");
const auth_middleware_1 = require("../auth/auth.middleware");
const router = (0, express_1.Router)();
// GET /api/profile - Get user profile
// Kullanıcı kimlik doğrulaması gerekli
router.get('/', auth_middleware_1.authenticateToken, profile_controller_1.getUserProfile);
// PUT /api/profile - Update user profile
// Kullanıcı kimlik doğrulaması gerekli
router.put('/', auth_middleware_1.authenticateToken, profile_controller_1.updateUserProfile);
exports.default = router;
