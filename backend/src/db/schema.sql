-- Drop existing tables if they exist
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS room_participants CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS user_subjects CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table 
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    university VARCHAR(255),
    department VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User profiles
CREATE TABLE user_profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    bio TEXT,
    profile_picture VARCHAR(255),
    is_online BOOLEAN DEFAULT FALSE,
    last_active TIMESTAMP
);

-- Subjects
CREATE TABLE subjects (
    subject_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

-- User subjects
CREATE TABLE user_subjects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    subject_id INTEGER REFERENCES subjects(subject_id) ON DELETE CASCADE,
    skill_level VARCHAR(50),
    interested_in_helping BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, subject_id)
);

-- Rooms
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_name VARCHAR(255) NOT NULL,
    subject_id INTEGER REFERENCES subjects(subject_id),
    is_public BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Room participants
CREATE TABLE room_participants (
    id SERIAL PRIMARY KEY,
    room_id INTEGER REFERENCES rooms(room_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(room_id, user_id)
);

-- Messages
CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    room_id INTEGER REFERENCES rooms(room_id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(user_id),
    message_type VARCHAR(50) DEFAULT 'text',
    message_text TEXT,
    file_url VARCHAR(255),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE
);

-- Reports
CREATE TABLE reports (
    report_id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES messages(message_id) ON DELETE CASCADE,
    reported_by INTEGER REFERENCES users(user_id),
    reason TEXT,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 

-- Function to count messages in a room
CREATE OR REPLACE FUNCTION count_room_messages(room_id_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    message_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO message_count
    FROM messages
    WHERE room_id = room_id_param;
    
    RETURN message_count;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to create notifications when a new message is sent
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    room_name_var VARCHAR(255);
    sender_name_var VARCHAR(255);
    participant_record RECORD;
    notification_content TEXT;
BEGIN
    -- Get room name
    SELECT room_name INTO room_name_var
    FROM rooms
    WHERE room_id = NEW.room_id;
    
    -- Get sender name
    SELECT full_name INTO sender_name_var
    FROM users
    WHERE user_id = NEW.sender_id;
    
    -- Create notification content
    notification_content := sender_name_var || ' sent a new message in ' || room_name_var;
    
    -- Insert notification for each room participant (except the sender)
    FOR participant_record IN 
        SELECT user_id 
        FROM room_participants 
        WHERE room_id = NEW.room_id AND user_id != NEW.sender_id
    LOOP
        INSERT INTO notifications (user_id, content)
        VALUES (participant_record.user_id, notification_content);
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new messages
CREATE TRIGGER message_notification_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_new_message();