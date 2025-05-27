# 🎓 Student Chat Application

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript"/>
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white" alt="Prisma"/>
</div>

## 📱 Overview

Student Chat is a modern, full-stack chat application designed specifically for students. Built with Flutter for the frontend and Node.js with TypeScript for the backend, this application provides a seamless and secure communication platform for educational purposes.

## ✨ Features

- 🔐 Secure Authentication System
- 💬 Real-time Chat Functionality
- 👤 User Profile Management
- 🎨 Modern Material Design 3 UI
- 📱 Cross-platform Support (iOS, Android, Web)
- 🔄 State Management with BLoC Pattern
- 🛡️ Type-safe Development with TypeScript
- 🗄️ Database Management with Prisma

## 🏗️ Architecture

### Frontend
- **Framework**: Flutter
- **State Management**: Flutter BLoC
- **UI Components**: Material Design 3
- **Key Features**:
  - Responsive Design
  - Clean Architecture
  - Dependency Injection
  - Route Management

### Backend
- **Runtime**: Node.js
- **Language**: TypeScript
- **Database ORM**: Prisma
- **Key Features**:
  - RESTful API
  - Type Safety
  - Modular Architecture
  - File Upload Support

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Node.js
- npm or yarn
- PostgreSQL Database
- Prisma CLI

### Environment Setup

1. Clone the repository
```bash
git clone https://github.com/yourusername/student_chat.git
```

2. Backend Setup
```bash
cd backend
npm install

# Create .env file from example
cp .env.example .env

# Edit .env file with your configuration
# Required environment variables:
# - DATABASE_URL: PostgreSQL connection string
# - JWT_SECRET: Secret key for JWT tokens
# - PORT: Server port (default: 3000)
# - CORS_ORIGIN: Allowed origins for CORS
# - UPLOADS_DIR: Directory for file uploads
# - MAX_FILE_SIZE: Maximum file size in bytes

# Generate Prisma client
npx prisma generate

# Start the server
npm run dev
```

3. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

## 🔧 Environment Variables

### Backend (.env)
```env
# Server Configuration
PORT=3000

# Database Configuration
DATABASE_URL="postgresql://user:password@localhost:5432/student_chat"

# JWT Configuration
JWT_SECRET="your-secret-key"
JWT_EXPIRES_IN="24h"

# CORS Configuration
CORS_ORIGIN="*"

# File Upload Configuration
UPLOADS_DIR="uploads"
MAX_FILE_SIZE=5242880  # 5MB in bytes
```

## 🛠️ Tech Stack

- **Frontend**:
  - Flutter
  - Flutter BLoC
  - Material Design 3
  - Dependency Injection

- **Backend**:
  - Node.js
  - TypeScript
  - Prisma
  - Express.js

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  Made with ❤️ by [Your Name]
</div>
