import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { Request } from 'express'; // Import Request type

// --- Multer Configuration ---
const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads'); // Adjust path relative to middleware dir
// Ensure uploads directory exists
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
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
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    if (file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf') {
        cb(null, true);
    } else {
        // Reject file with an error message
        cb(new Error('Invalid file type. Only images and PDFs are allowed.'));
    }
};

// Export the configured multer instance
export const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});
