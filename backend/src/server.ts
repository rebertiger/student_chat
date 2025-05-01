import express, { Request, Response, NextFunction } from 'express';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
// import multer from 'multer'; // Removed - now in multer.config.ts
import path from 'path'; // Import path
import fs from 'fs'; // Import fs to ensure uploads directory exists
import prisma from './db'; // Import the Prisma client instance
import authRoutes from './features/auth/auth.routes'; // Import auth routes
import roomRoutes from './features/rooms/room.routes'; // Import room routes

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
        } else {
            console.error(`Socket ${socket.id} tried to join invalid room: ${roomId}`);
        }
    });

    // Handle incoming text messages
    socket.on('sendMessage', async (data) => {
        console.log(`[Socket ${socket.id}] Received sendMessage event with data:`, data); // Added log
        // TODO: Add validation and get authenticated user ID
        const { roomId, messageText } = data;
        const senderId = 1; // Placeholder - Replace with actual user ID

        if (!roomId || !messageText || !senderId) {
            console.error(`[Socket ${socket.id}] Invalid message data received:`, data);
            // Optional: emit error back to sender
            // socket.emit('messageError', 'Invalid message data');
            return;
        }

        console.log(`[Socket ${socket.id}] Processing message for room ${roomId}, sender ${senderId}`); // Added log

        try {
            // 1. Save message to database
            console.log(`[Socket ${socket.id}] Attempting to save message to DB...`); // Added log
            const newMessage = await prisma.message.create({
                data: {
                    room_id: parseInt(roomId, 10),
                    sender_id: senderId,
                    message_text: messageText,
                    message_type: 'text', // Explicitly set type
                },
                include: { // Include sender details for broadcasting
                    sender: { select: { user_id: true, full_name: true } }
                }
            });
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
        prisma.$disconnect(); // Disconnect Prisma
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        prisma.$disconnect(); // Disconnect Prisma
    });
});
