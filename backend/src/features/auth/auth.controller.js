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
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.login = exports.register = void 0;
const db_1 = __importDefault(require("../../db"));
const bcrypt_1 = __importDefault(require("bcrypt"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const executeQuery = db_1.default.query;
const SALT_ROUNDS = 10; // Standard salt rounds for bcrypt
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key'; // JWT secret key - Bu değer normalde environment variable'dan alınmalıdır
const register = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, password, full_name, university, department } = req.body;
    // Basic validation
    if (!email || !password || !full_name) {
        return res.status(400).json({ message: 'Email, password, and full name are required.' });
    }
    try {
        // Check if user already exists
        const existingUserResult = yield executeQuery('SELECT * FROM users WHERE email = $1', [email]);
        const existingUser = existingUserResult.rows.length > 0 ? existingUserResult.rows[0] : null;
        if (existingUser) {
            return res.status(409).json({ message: 'User with this email already exists.' });
        }
        // Hash password
        const password_hash = yield bcrypt_1.default.hash(password, SALT_ROUNDS);
        // Create user
        const newUserResult = yield executeQuery(
            'INSERT INTO users (email, password_hash, full_name, university, department) VALUES ($1, $2, $3, $4, $5) RETURNING user_id, email, full_name, university, department, created_at',
            [email, password_hash, full_name, university, department]
        );
        
        const newUser = newUserResult.rows[0];
        // Optionally create a profile entry (can be done later or upon first profile edit)
        // await prisma.userProfile.create({ data: { user_id: newUser.user_id } });
        res.status(201).json({ message: 'User registered successfully', user: newUser });
    }
    catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Internal server error during registration.' });
    }
});
exports.register = register;
const login = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required.' });
    }
    try {
        // Find user by email
        const userResult = yield executeQuery('SELECT * FROM users WHERE email = $1', [email]);
        
        if (userResult.rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }
        
        const user = userResult.rows[0];
        // User existence already checked above
        // Compare password with hash
        const isMatch = yield bcrypt_1.default.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' }); // Generic message
        }
        // Login successful - create and return JWT token
        const token = jsonwebtoken_1.default.sign({ userId: user.user_id }, JWT_SECRET, { expiresIn: '24h' });
        const { password_hash } = user, userData = __rest(user, ["password_hash"]);
        res.status(200).json({
            message: 'Giriş başarılı',
            user: userData,
            token: token
        });
    }
    catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Internal server error during login.' });
    }
});
exports.login = login;
