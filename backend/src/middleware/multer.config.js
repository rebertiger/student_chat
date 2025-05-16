"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.upload = void 0;
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
// --- Multer Configuration ---
const UPLOADS_DIR = path_1.default.join(__dirname, '..', '..', 'uploads'); // Adjust path relative to middleware dir
// Ensure uploads directory exists
if (!fs_1.default.existsSync(UPLOADS_DIR)) {
    fs_1.default.mkdirSync(UPLOADS_DIR, { recursive: true });
}
const storage = multer_1.default.diskStorage({
    destination: function (req, file, cb) {
        cb(null, UPLOADS_DIR); // Set destination folder
    },
    filename: function (req, file, cb) {
        // Create a unique filename: timestamp-originalname
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + '-' + file.originalname);
    }
});
// File filter (optional: accept only images/pdfs)
const fileFilter = (req, file, cb) => {
    console.log('Received file MIME type:', file.mimetype); // Log the received MIME type
    if (file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf') {
        cb(null, true);
    }
    else {
        // Reject file with an error message
        cb(new Error('Invalid file type. Only images and PDFs are allowed.'));
    }
};
// Export the configured multer instance
exports.upload = (0, multer_1.default)({
    storage: storage,
    fileFilter: fileFilter,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});
