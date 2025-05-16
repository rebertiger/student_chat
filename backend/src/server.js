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
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
// import multer from 'multer'; // Removed - now in multer.config.ts
const path_1 = __importDefault(require("path")); // Import path
const fs_1 = __importDefault(require("fs")); // Import fs to ensure uploads directory exists
const db_1 = __importDefault(require("./db")); // Import the Prisma client instance
const auth_routes_1 = __importDefault(require("./features/auth/auth.routes")); // Import auth routes
const room_routes_1 = __importDefault(require("./features/rooms/room.routes")); // Import room routes
const profile_routes_1 = __importDefault(require("./features/profile/profile.routes")); // Import profile routes
const report_routes_1 = __importDefault(require("./features/reports/report.routes")); // Import report routes
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*", // Allow all origins for now (adjust for production)
        methods: ["GET", "POST"]
    },
    pingInterval: 25000, // Send pings every 25 seconds
    pingTimeout: 60000 // Wait 60 seconds for pong response
});
const PORT = process.env.PORT || 3000;
// Define uploads directory path (still needed for static serving)
const UPLOADS_DIR = path_1.default.join(__dirname, '..', 'uploads');
// Ensure uploads directory exists (good practice to keep)
if (!fs_1.default.existsSync(UPLOADS_DIR)) {
    fs_1.default.mkdirSync(UPLOADS_DIR, { recursive: true });
}
// Make io instance available in request handlers
app.set('io', io);
// --- Middleware ---
app.use(express_1.default.json()); // Parse JSON bodies
app.use('/uploads', express_1.default.static(UPLOADS_DIR)); // Serve files from uploads directory
// --- Basic Route ---
app.get('/', (req, res) => {
    res.send('Student Chat Backend is running!');
});
// --- API Routes ---
app.use('/api/auth', auth_routes_1.default);
app.use('/api/rooms', room_routes_1.default);
app.use('/api/profile', profile_routes_1.default);
app.use('/api/reports', report_routes_1.default); // Add the new reports route
// Example: app.use('/api/messages', messageRoutes);
// --- Socket.IO Connection Handling ---
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);
    // Placeholder for socket event listeners (joinRoom, sendMessage, etc.)
    // Handle user joining a room
    socket.on('joinRoom', (roomId) => {
        // TODO: Add validation/authentication if needed
        if (roomId) {
            const roomIdentifier = `room_${roomId}`;
            console.log(`Socket ${socket.id} joining room: ${roomIdentifier}`);
            socket.join(roomIdentifier);
            // Optional: Send confirmation or fetch history for the user
            // socket.emit('joinedRoom', roomId);
        }
        else {
            console.error(`Socket ${socket.id} tried to join invalid room: ${roomId}`);
        }
    });
    // Handle incoming text and file messages
    socket.on('sendMessage', (data) => __awaiter(void 0, void 0, void 0, function* () {
        console.log(`[Socket ${socket.id}] Received sendMessage event with data:`, data); // Added log
        // Kullanıcı bilgilerini frontend'den al
        const { roomId, messageText, messageType = 'text', fileUrl, senderId, senderFullName } = data;
        // Eğer senderId gönderilmediyse varsayılan değer kullan
        const actualSenderId = senderId || 1; // Fallback to default if not provided
        if (!roomId || (messageType === 'text' && !messageText) || (messageType !== 'text' && !fileUrl)) {
            console.error(`[Socket ${socket.id}] Invalid message data received:`, data);
            socket.emit('messageError', 'Invalid message data');
            return;
        }
        console.log(`[Socket ${socket.id}] Processing message for room ${roomId}, sender ${actualSenderId}`); // Added log
        try {
            // 1. Save message to database
            console.log(`[Socket ${socket.id}] Attempting to save message to DB...`); // Added log
            // Eğer senderFullName gönderildiyse, özel bir mesaj nesnesi oluştur
            let messageData = {
                room_id: parseInt(roomId, 10),
                sender_id: actualSenderId,
                message_text: messageType === 'text' ? messageText : fileUrl,
                message_type: messageType,
                file_url: messageType !== 'text' ? fileUrl : null
            };
            const newMessage = yield db_1.default.message.create({
                data: messageData,
                include: {
                    sender: { select: { user_id: true, full_name: true } }
                }
            });
            // Eğer frontend'den senderFullName geldiyse ve sender null değilse, veritabanından gelen değeri değiştir
            if (senderFullName && newMessage.sender) {
                newMessage.sender.full_name = senderFullName;
            }
            else if (senderFullName && !newMessage.sender) {
                // Eğer sender null ise, yeni bir sender objesi oluştur
                newMessage.sender = {
                    user_id: actualSenderId,
                    full_name: senderFullName
                };
            }
            console.log(`[Socket ${socket.id}] Message saved successfully (ID: ${newMessage.message_id})`); // Added log
            // 2. Broadcast message to all clients in the room
            const roomIdentifier = `room_${roomId}`;
            console.log(`[Socket ${socket.id}] Broadcasting 'newMessage' to room ${roomIdentifier}`); // Added log
            io.to(roomIdentifier).emit('newMessage', newMessage);
            console.log(`[Socket ${socket.id}] Message broadcasted to room ${roomIdentifier}:`, newMessage.message_text);
        }
        catch (error) {
            console.error(`[Socket ${socket.id}] Error saving/broadcasting message for room ${roomId}:`, error);
            // Optional: emit error back to sender
            // socket.emit('messageError', 'Failed to send message');
        }
    }));
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
        // TODO: Handle leaving rooms if necessary
    });
});
// Basic Error Handling Middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
});
// Start Server
server.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
// Graceful shutdown (optional but good practice)
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        db_1.default.$disconnect(); // Disconnect Prisma
    });
});
process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        db_1.default.$disconnect(); // Disconnect Prisma
    });
});
