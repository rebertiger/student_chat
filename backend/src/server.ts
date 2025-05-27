import express, { Request, Response, NextFunction } from 'express';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
// import multer from 'multer'; // Removed - now in multer.config.ts
import path from 'path'; // Import path
import fs from 'fs'; // Import fs to ensure uploads directory exists
import pool from './db'; // Import the database connection
import authRoutes from './features/auth/auth.routes'; // Import auth routes
import roomRoutes from './features/rooms/room.routes'; // Import room routes
import profileRoutes from './features/profile/profile.routes'; // Import profile routes
import subjectsRoutes from './features/subjects/subjects.routes';
import messageRoutes from './features/messages/message.routes'; // Import message routes

const app = express();
const server = http.createServer(app);
const io = new SocketIOServer(server, {
    cors: {
        origin: "*", // Allow all origins for now (adjust for production)
        methods: ["GET", "POST"]
    },
    pingInterval: 25000, // Send pings every 25 seconds
    pingTimeout: 60000 // Wait 60 seconds for pong response
});

const PORT = process.env.PORT || 3000;

// Define uploads directory path (still needed for static serving)
const UPLOADS_DIR = path.join(__dirname, '..', 'uploads');
// Ensure uploads directory exists (good practice to keep)
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Make io instance available in request handlers
app.set('io', io);


// --- Middleware ---
app.use(express.json()); // Parse JSON bodies
app.use('/uploads', express.static(UPLOADS_DIR)); // Serve files from uploads directory


// --- Basic Route ---
app.get('/', (req: Request, res: Response) => {
    res.send('Student Chat Backend is running!');
});

// --- API Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/subjects', subjectsRoutes);
app.use('/api/messages', messageRoutes);

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
        } else {
            console.error(`Socket ${socket.id} tried to join invalid room: ${roomId}`);
        }
    });

    // Handle incoming text and file messages
    socket.on('sendMessage', async (data) => {
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
            // Save message using raw SQL
            const result = await pool.query(
                `INSERT INTO messages (room_id, sender_id, message_type, message_text, file_url)
                 VALUES ($1, $2, $3, $4, $5)
                 RETURNING *`,
                [roomId, actualSenderId, messageType, messageType === 'text' ? messageText : null, messageType !== 'text' ? fileUrl : null]
            );

            const newMessage = result.rows[0];
            
            // Get sender's full name
            const userResult = await pool.query(
                'SELECT full_name FROM users WHERE user_id = $1',
                [actualSenderId]
            );

            newMessage.sender = {
                user_id: actualSenderId,
                full_name: senderFullName || userResult.rows[0]?.full_name || 'Unknown User'
            };

            console.log(`[Socket ${socket.id}] Message saved successfully (ID: ${newMessage.message_id})`); // Added log

            // 2. Broadcast message to all clients in the room
            const roomIdentifier = `room_${roomId}`;
            console.log(`[Socket ${socket.id}] Broadcasting 'newMessage' to room ${roomIdentifier}`); // Added log
            io.to(roomIdentifier).emit('newMessage', newMessage);
            console.log(`[Socket ${socket.id}] Message broadcasted to room ${roomIdentifier}:`, newMessage.message_text);

        } catch (error) {
            console.error(`[Socket ${socket.id}] Error saving/broadcasting message for room ${roomId}:`, error);
            // Optional: emit error back to sender
            // socket.emit('messageError', 'Failed to send message');
        }
    });


    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
        // TODO: Handle leaving rooms if necessary
    });
});


// Basic Error Handling Middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
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
        pool.end();
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        pool.end();
    });
});
