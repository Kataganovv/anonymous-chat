const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const cors = require('cors');

// Создаем Express приложение
const app = express();
const server = http.createServer(app);

// Настраиваем Socket.IO с CORS
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"],
        credentials: false
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Хранилище для активных пользователей и сообщений
const activeUsers = new Map();
const messages = [];
const MAX_MESSAGES = 100; // Максимум сообщений в памяти

// Генерация цветов для пользователей
const colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
];

function getRandomColor() {
    return colors[Math.floor(Math.random() * colors.length)];
}

// Генерация ID
function generateId() {
    return Math.random().toString(36).substr(2, 9);
}

// Форматирование времени
function formatTime(date = new Date()) {
    return date.toISOString();
}

// Socket.IO соединения
io.on('connection', (socket) => {
    console.log(`✅ Пользователь подключился: ${socket.id}`);
    
    // Отправляем последние сообщения новому пользователю
    socket.emit('messages_history', messages.slice(-50));
    
    // Обновляем счетчик онлайн пользователей
    updateOnlineCount();
    
    // Обработка присоединения пользователя
    socket.on('user_join', (userData) => {
        const user = {
            id: socket.id,
            name: userData.name || `Гость_${socket.id.slice(-4)}`,
            color: userData.color || getRandomColor(),
            joinedAt: new Date()
        };
        
        activeUsers.set(socket.id, user);
        
        // Уведомляем всех о новом пользователе
        const joinMessage = {
            id: generateId(),
            type: 'system',
            text: `${user.name} присоединился к чату`,
            timestamp: formatTime(),
            userId: socket.id,
            author: 'Система'
        };
        
        messages.push(joinMessage);
        if (messages.length > MAX_MESSAGES) {
            messages.shift();
        }
        
        io.emit('message', joinMessage);
        updateOnlineCount();
        
        console.log(`👤 ${user.name} присоединился к чату`);
    });
    
    // Обработка отправки сообщения
    socket.on('send_message', (messageData) => {
        const user = activeUsers.get(socket.id);
        if (!user) {
            socket.emit('error', { message: 'Пользователь не найден' });
            return;
        }
        
        // Валидация сообщения
        if (!messageData.text || messageData.text.trim().length === 0) {
            socket.emit('error', { message: 'Сообщение не может быть пустым' });
            return;
        }
        
        if (messageData.text.length > 1000) {
            socket.emit('error', { message: 'Сообщение слишком длинное' });
            return;
        }
        
        const message = {
            id: generateId(),
            type: 'user',
            text: messageData.text.trim(),
            author: user.name,
            userId: socket.id,
            color: user.color,
            timestamp: formatTime(),
            emoji: messageData.emoji || null
        };
        
        messages.push(message);
        if (messages.length > MAX_MESSAGES) {
            messages.shift();
        }
        
        // Отправляем сообщение всем подключенным пользователям
        io.emit('message', message);
        
        console.log(`💬 ${user.name}: ${message.text}`);
    });
    
    // Обработка индикатора печатания
    socket.on('typing_start', () => {
        const user = activeUsers.get(socket.id);
        if (user) {
            socket.broadcast.emit('user_typing', {
                userId: socket.id,
                userName: user.name
            });
        }
    });
    
    socket.on('typing_stop', () => {
        socket.broadcast.emit('user_stop_typing', {
            userId: socket.id
        });
    });
    
    // Обработка отключения
    socket.on('disconnect', () => {
        const user = activeUsers.get(socket.id);
        if (user) {
            // Уведомляем о выходе пользователя
            const leaveMessage = {
                id: generateId(),
                type: 'system',
                text: `${user.name} покинул чат`,
                timestamp: formatTime(),
                userId: socket.id,
                author: 'Система'
            };
            
            messages.push(leaveMessage);
            if (messages.length > MAX_MESSAGES) {
                messages.shift();
            }
            
            socket.broadcast.emit('message', leaveMessage);
            activeUsers.delete(socket.id);
            updateOnlineCount();
            
            console.log(`❌ ${user.name} покинул чат`);
        }
    });
});

// Функция обновления счетчика онлайн пользователей
function updateOnlineCount() {
    const count = activeUsers.size;
    io.emit('online_count', count);
    console.log(`👥 Онлайн пользователей: ${count}`);
}

// REST API эндпоинты
app.get('/api/status', (req, res) => {
    res.json({
        status: 'active',
        online_users: activeUsers.size,
        total_messages: messages.length,
        uptime: process.uptime(),
        server_time: new Date().toISOString()
    });
});

app.get('/api/messages', (req, res) => {
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    
    const recentMessages = messages
        .slice(-limit - offset, messages.length - offset)
        .reverse();
        
    res.json({
        messages: recentMessages,
        total: messages.length,
        online_users: activeUsers.size
    });
});

// Основная страница
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Запуск сервера
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 Сервер запущен на порту ${PORT}`);
    console.log(`🌐 Локальный доступ: http://localhost:${PORT}`);
    console.log(`📱 Для мобильных устройств в той же сети: http://[ваш-IP]:${PORT}`);
    console.log('💬 Чат сервер готов к работе!');
});

// Обработка ошибок
process.on('uncaughtException', (error) => {
    console.error('❌ Критическая ошибка:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Необработанное отклонение промиса:', reason);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Получен сигнал SIGTERM, завершение работы...');
    server.close(() => {
        console.log('✅ Сервер успешно остановлен');
        process.exit(0);
    });
});

module.exports = { app, server, io };