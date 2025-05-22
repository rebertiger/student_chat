import express, { Request, Response, NextFunction } from 'express';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import path from 'path';
import fs from 'fs';
import pool, { query as executeQuery } from './db'; // Updated import
import authRoutes from './features/auth/auth.routes';
import roomRoutes from './features/rooms/room.routes';
import profileRoutes from './features/profile/profile.routes';
import reportRoutes from './features/reports/report.routes';

const app = express();
const server = http.createServer(app);
const io = new SocketIOServer(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    },
    pingInterval: 25000,
    pingTimeout: 60000
});

const PORT = process.env.PORT || 3000;

const UPLOADS_DIR = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

app.set('io', io);

app.use(express.json());
app.use('/uploads', express.static(UPLOADS_DIR));

app.get('/', (req: Request, res: Response) => {
    res.send('Student Chat Backend is running!');
});

app.use('/api/auth', authRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/reports', reportRoutes);

io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    socket.on('joinRoom', (roomId) => {
        if (roomId) {
            const roomIdentifier = `room_${roomId}`;
            console.log(`Socket ${socket.id} joining room: ${roomIdentifier}`);
            socket.join(roomIdentifier);
        } else {
            console.error(`Socket ${socket.id} tried to join invalid room: ${roomId}`);
        }
    });

    socket.on('sendMessage', async (data) => {
        console.log(`[Socket ${socket.id}] Received sendMessage event with data:`, data);
        const { roomId, messageText, messageType = 'text', fileUrl, senderId, senderFullName } = data;
        const actualSenderId = senderId; // Assuming senderId is now reliably sent from frontend or derived from token

        if (!actualSenderId) {
            console.error(`[Socket ${socket.id}] Sender ID is missing:`, data);
            socket.emit('messageError', 'Sender ID is required to send a message.');
            return;
        }

        if (!roomId || (messageType === 'text' && !messageText) || (messageType !== 'text' && !fileUrl)) {
            console.error(`[Socket ${socket.id}] Invalid message data received:`, data);
            socket.emit('messageError', 'Invalid message data');
            return;
        }

        console.log(`[Socket ${socket.id}] Processing message for room ${roomId}, sender ${actualSenderId}`);

        try {
            console.log(`[Socket ${socket.id}] Attempting to save message to DB...`);
            
            const insertQuery = 
                `INSERT INTO messages (room_id, sender_id, message_text, message_type, file_url)
                 VALUES ($1, $2, $3, $4, $5)
                 RETURNING message_id, room_id, sender_id, message_text, message_type, file_url, sent_at, is_edited`;
            
            const values = [
                parseInt(roomId, 10),
                actualSenderId,
                messageType === 'text' ? messageText : (fileUrl ? messageText : null), // message_text is original filename for files
                messageType,
                messageType !== 'text' ? fileUrl : null
            ];

            const result = await executeQuery(insertQuery, values);
            const savedMessage = result.rows[0];

            console.log(`[Socket ${socket.id}] Message saved to DB:`, savedMessage);

            // Prepare message for broadcast, including sender's full name
            // We need to fetch sender's full name if not provided directly with message
            // For simplicity, assuming senderFullName is passed or can be fetched if needed.
            // If senderFullName is not in `data`, you might need another query here to get it based on actualSenderId.
            const messageToBroadcast = {
                ...savedMessage,
                sender: {
                    user_id: actualSenderId,
                    full_name: senderFullName || 'Unknown User' // Use provided or fallback
                }
            };

            const roomIdentifier = `room_${roomId}`;
            io.to(roomIdentifier).emit('newMessage', messageToBroadcast);
            console.log(`[Socket ${socket.id}] Message broadcasted to room ${roomIdentifier}:`, messageToBroadcast);

        } catch (error) {
            console.error(`[Socket ${socket.id}] Error saving or broadcasting message:`, error);
            socket.emit('messageError', 'Error processing message');
        }
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
        // TODO: Handle user leaving rooms, updating presence, etc.
    });

    // Error handling for socket
    socket.on('error', (error) => {
        console.error(`Socket error for ${socket.id}:`, error);
    });
});

// Global error handler for Express
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error("Global error handler caught an error:", err);
    res.status(500).json({ message: 'Internal Server Error', error: err.message });
});

server.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('SIGINT signal received: closing HTTP server');
    io.close(() => {
        console.log('Socket.IO server closed');
    });
    server.close(async () => {
        console.log('HTTP server closed');
        try {
            await pool.end();
            console.log('Database pool has ended');
        } catch (err) {
            console.error('Error ending the database pool', err);
        }
        process.exit(0);
    });
});
