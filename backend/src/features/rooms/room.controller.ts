import { Request, Response } from 'express';
import { Server as SocketIOServer } from 'socket.io'; // Import SocketIO Server type
import prisma from '../../db';

// Get all public rooms (or rooms the user is part of - requires auth later)
export const getRooms = async (req: Request, res: Response) => {
    try {
        // TODO: Implement filtering based on user participation or just public rooms
        const rooms = await prisma.room.findMany({
            where: {
                is_public: true // For now, only fetch public rooms
            },
            orderBy: {
                created_at: 'desc' // Show newest rooms first
            },
            // Optionally include subject or creator info
            include: {
                subject: { select: { name: true } },
                creator: { select: { user_id: true, full_name: true } }
            }
        });
        res.status(200).json(rooms);
    } catch (error) {
        console.error('Error fetching rooms:', error);
        res.status(500).json({ message: 'Internal server error fetching rooms.' });
    }
};

// Create a new room
export const createRoom = async (req: Request, res: Response) => {
    // TODO: Add authentication middleware to get created_by user ID
    const { room_name, subject_id, is_public, created_by, creator_full_name } = req.body;
    const created_by_user_id = created_by ? parseInt(created_by, 10) : 1; // Eğer gönderildiyse kullan, yoksa 1
    const creatorName = creator_full_name || null;

    if (!room_name) {
        return res.status(400).json({ message: 'Room name is required.' });
    }

    try {
        const newRoom = await prisma.room.create({
            data: {
                room_name,
                subject_id: subject_id ? parseInt(subject_id, 10) : null, // Ensure subject_id is integer or null
                is_public: is_public !== undefined ? Boolean(is_public) : true, // Default to public
                created_by: created_by_user_id, // Link to the creator
                creator_full_name: creatorName, // Oda oluşturan kişinin adı
            },
             include: { // Include creator info in the response
                creator: { select: { user_id: true, full_name: true } }
            }
        });

        // Automatically add the creator as a participant
        await prisma.roomParticipant.create({
            data: {
                room_id: newRoom.room_id,
                user_id: created_by_user_id,
            }
        });

        // TODO: Potentially emit a socket event for new room creation

        res.status(201).json({ message: 'Room created successfully', room: newRoom });

    } catch (error) {
        console.error('Error creating room:', error);
        // Handle potential errors like invalid subject_id if foreign key constraint fails
        if (error instanceof Error && error.message.includes('foreign key constraint')) {
             return res.status(400).json({ message: 'Invalid subject ID provided.' });
        }
        res.status(500).json({ message: 'Internal server error creating room.' });
    }
};

// Get details for a specific room (Example - might be needed later)
export const getRoomById = async (req: Request, res: Response) => {
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        const room = await prisma.room.findUnique({
            where: { room_id: roomId },
            include: {
                subject: true,
                creator: { select: { user_id: true, full_name: true } },
                participants: { // Include participants
                    include: {
                        user: { select: { user_id: true, full_name: true } }
                    }
                },
                // Optionally include messages later
            }
        });

        if (!room) {
            return res.status(404).json({ message: 'Room not found.' });
        }

        // TODO: Add authorization check - is user allowed to see this room?

        res.status(200).json(room);
    } catch (error) {
        console.error(`Error fetching room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error fetching room details.' });
    }
};

// Join a room
export const joinRoom = async (req: Request, res: Response) => {
    // TODO: Add authentication middleware to get user ID
    const userId = 1; // Placeholder - Replace with actual user ID from auth token
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        // Check if room exists (optional, FK constraint might handle this)
        const roomExists = await prisma.room.findUnique({ where: { room_id: roomId } });
        if (!roomExists) {
            return res.status(404).json({ message: 'Room not found.' });
        }

        // Check if user is already a participant
        const existingParticipant = await prisma.roomParticipant.findFirst({
            where: {
                room_id: roomId,
                user_id: userId,
            },
        });

        if (existingParticipant) {
            // User is already in the room, just return success
            return res.status(200).json({ message: 'Already joined this room.' });
        }

        // Add user to the room
        await prisma.roomParticipant.create({
            data: {
                room_id: roomId,
                user_id: userId,
            },
        });

        // TODO: Emit socket event if needed ('userJoined', { userId, roomId })

        res.status(200).json({ message: 'Successfully joined the room.' });

    } catch (error) {
        console.error(`Error joining room ${roomId} for user ${userId}:`, error);
        res.status(500).json({ message: 'Internal server error joining room.' });
    }
};

// Get messages for a specific room
export const getMessagesForRoom = async (req: Request, res: Response) => {
    // TODO: Add authentication middleware and check if user is participant
    const userId = 1; // Placeholder
    const roomId = parseInt(req.params.roomId, 10);

     if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    try {
        // Optional: Verify user is participant first
        // const participant = await prisma.roomParticipant.findFirst({ where: { room_id: roomId, user_id: userId }});
        // if (!participant) {
        //     return res.status(403).json({ message: 'Access denied. You are not in this room.' });
        // }

        const messages = await prisma.message.findMany({
            where: { room_id: roomId },
            orderBy: { sent_at: 'asc' }, // Oldest messages first
            include: {
                sender: { // Include sender's full name
                    select: {
                        user_id: true,
                        full_name: true,
                    }
                }
            }
        });

        res.status(200).json(messages);

    } catch (error) {
         console.error(`Error fetching messages for room ${roomId}:`, error);
        res.status(500).json({ message: 'Internal server error fetching messages.' });
    }
};

// Handle file upload for a room
export const uploadFile = async (req: Request, res: Response) => {
    // TODO: Add authentication middleware and check if user is participant
    const userId = 1; // Placeholder
    const roomId = parseInt(req.params.roomId, 10);

    if (isNaN(roomId)) {
        return res.status(400).json({ message: 'Invalid room ID.' });
    }

    if (!req.file) {
        return res.status(400).json({ message: 'No file uploaded.' });
    }

    try {
        // Optional: Verify user is participant first

        const file = req.file;
        const fileUrl = `/uploads/${file.filename}`; // Relative URL path
        const messageType = file.mimetype.startsWith('image/') ? 'image' : 'pdf';

        // 1. Save message reference to database
        const newMessage = await prisma.message.create({
            data: {
                room_id: roomId,
                sender_id: userId,
                message_type: messageType,
                message_text: file.originalname, // Store original filename as text
                file_url: fileUrl,
            },
             include: { // Include sender details for broadcasting
                sender: { select: { user_id: true, full_name: true } }
            }
        });

         // 2. Broadcast message to all clients in the room via WebSocket
        const roomIdentifier = `room_${roomId}`;
        // Need access to the io instance. This is tricky here.
        // Option 1: Pass io instance down (complex)
        // Option 2: Emit an event that server.ts listens for (better separation)
        // Option 3: (Simplest for now) Import io directly (tight coupling) - Let's avoid this.
        // For now, we'll just return the message, WebSocket broadcast needs refactoring. - REFACTORED!
        console.log(`File uploaded for room ${roomIdentifier}, message saved:`, newMessage);
        // Broadcast the new file message via WebSocket
        const io = req.app.get('io') as SocketIOServer; // Get io instance from app settings
        io.to(roomIdentifier).emit('newMessage', newMessage);
        console.log(`File message broadcasted to room ${roomIdentifier}`);


        res.status(201).json({ message: 'File uploaded successfully', messageData: newMessage }); // Return message data as well

    } catch (error) {
        console.error(`Error uploading file for room ${roomId}:`, error);
        // Clean up uploaded file if DB save fails? (More advanced error handling)
        res.status(500).json({ message: 'Internal server error uploading file.' });
    }
};
