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
exports.authenticateToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../../db"));
// JWT secret key - Bu değer normalde environment variable'dan alınmalıdır
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
/**
 * JWT token doğrulama middleware'i
 * Bu middleware, gelen isteklerdeki JWT token'ı doğrular ve kullanıcı bilgilerini request nesnesine ekler
 */
const authenticateToken = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN formatından token'ı ayıklıyoruz
        if (!token) {
            return res.status(401).json({ message: 'Yetkilendirme tokenı bulunamadı' });
        }
        // Token'ı doğrula
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        // Kullanıcıyı veritabanından bul
        const user = yield db_1.default.user.findUnique({
            where: { user_id: decoded.userId },
            select: {
                user_id: true,
                email: true,
                full_name: true
            }
        });
        if (!user) {
            return res.status(401).json({ message: 'Geçersiz kullanıcı' });
        }
        // Kullanıcı bilgilerini request nesnesine ekle
        req.user = user;
        next();
    }
    catch (error) {
        if (error instanceof jsonwebtoken_1.default.JsonWebTokenError) {
            return res.status(401).json({ message: 'Geçersiz token' });
        }
        console.error('Auth middleware error:', error);
        return res.status(500).json({ message: 'Kimlik doğrulama sırasında bir hata oluştu' });
    }
});
exports.authenticateToken = authenticateToken;
