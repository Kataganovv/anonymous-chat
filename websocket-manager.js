// WebSocket менеджер для реального чата
class WebSocketManager {
    constructor() {
        this.socket = null;
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000;
        this.user = null;
        this.messageCallbacks = [];
        this.statusCallbacks = [];
        
        this.init();
    }
    
    init() {
        // Определяем URL сервера
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.hostname;
        const port = window.location.port || (protocol === 'wss:' ? '443' : '80');
        
        // Для разработки используем localhost:3000, для продакшена - текущий хост
        let serverURL;
        if (host === 'localhost' || host === '127.0.0.1') {
            serverURL = 'http://localhost:3000';
        } else {
            serverURL = `${window.location.protocol}//${host}:3000`;
        }
        
        console.log('🔌 Подключение к серверу:', serverURL);
        
        this.socket = io(serverURL, {
            transports: ['websocket', 'polling'],
            timeout: 5000,
            forceNew: true
        });
        
        this.setupEventListeners();
    }
    
    setupEventListeners() {
        // Подключение
        this.socket.on('connect', () => {
            console.log('✅ Подключен к серверу');
            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.notifyStatusCallbacks('connected');
            
            // Автоматически присоединяемся если есть пользователь
            if (this.user) {
                this.joinChat(this.user.name, this.user.color);
            }
        });
        
        // Отключение
        this.socket.on('disconnect', (reason) => {
            console.log('❌ Отключен от сервера:', reason);
            this.isConnected = false;
            this.notifyStatusCallbacks('disconnected');
            
            // Попытка переподключения
            if (reason !== 'io client disconnect') {
                this.attemptReconnect();
            }
        });
        
        // Ошибка подключения
        this.socket.on('connect_error', (error) => {
            console.error('❌ Ошибка подключения:', error);
            this.isConnected = false;
            this.notifyStatusCallbacks('connection_error');
            this.attemptReconnect();
        });
        
        // Получение сообщения
        this.socket.on('message', (message) => {
            this.notifyMessageCallbacks('message', message);
        });
        
        // История сообщений
        this.socket.on('messages_history', (messages) => {
            this.notifyMessageCallbacks('history', messages);
        });
        
        // Количество онлайн пользователей
        this.socket.on('online_count', (count) => {
            this.notifyStatusCallbacks('online_count', count);
        });
        
        // Пользователь печатает
        this.socket.on('user_typing', (data) => {
            this.notifyMessageCallbacks('user_typing', data);
        });
        
        this.socket.on('user_stop_typing', (data) => {
            this.notifyMessageCallbacks('user_stop_typing', data);
        });
        
        // Ошибки
        this.socket.on('error', (error) => {
            console.error('❌ Ошибка сервера:', error);
            this.notifyStatusCallbacks('server_error', error);
        });
    }
    
    attemptReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
            
            console.log(`🔄 Попытка переподключения ${this.reconnectAttempts}/${this.maxReconnectAttempts} через ${delay}ms`);
            
            setTimeout(() => {
                if (!this.isConnected) {
                    this.socket.connect();
                }
            }, delay);
        } else {
            console.error('❌ Превышено максимальное количество попыток переподключения');
            this.notifyStatusCallbacks('max_reconnect_attempts');
        }
    }
    
    // Присоединиться к чату
    joinChat(userName, userColor) {
        if (!this.isConnected) {
            console.warn('⚠️ Нет подключения к серверу');
            return false;
        }
        
        this.user = { name: userName, color: userColor };
        this.socket.emit('user_join', this.user);
        return true;
    }
    
    // Отправить сообщение
    sendMessage(text, emoji = null) {
        if (!this.isConnected) {
            console.warn('⚠️ Нет подключения к серверу');
            return false;
        }
        
        if (!text || text.trim().length === 0) {
            console.warn('⚠️ Пустое сообщение');
            return false;
        }
        
        this.socket.emit('send_message', {
            text: text.trim(),
            emoji: emoji
        });
        
        return true;
    }
    
    // Индикатор печатания
    startTyping() {
        if (this.isConnected) {
            this.socket.emit('typing_start');
        }
    }
    
    stopTyping() {
        if (this.isConnected) {
            this.socket.emit('typing_stop');
        }
    }
    
    // Подписка на сообщения
    onMessage(callback) {
        this.messageCallbacks.push(callback);
    }
    
    // Подписка на статус
    onStatus(callback) {
        this.statusCallbacks.push(callback);
    }
    
    // Уведомление подписчиков о сообщениях
    notifyMessageCallbacks(type, data) {
        this.messageCallbacks.forEach(callback => {
            try {
                callback(type, data);
            } catch (error) {
                console.error('❌ Ошибка в callback сообщения:', error);
            }
        });
    }
    
    // Уведомление подписчиков о статусе
    notifyStatusCallbacks(type, data) {
        this.statusCallbacks.forEach(callback => {
            try {
                callback(type, data);
            } catch (error) {
                console.error('❌ Ошибка в callback статуса:', error);
            }
        });
    }
    
    // Получить статус подключения
    getConnectionStatus() {
        return {
            connected: this.isConnected,
            reconnectAttempts: this.reconnectAttempts,
            user: this.user
        };
    }
    
    // Отключиться
    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
        }
    }
}

// Создаем глобальный экземпляр WebSocket менеджера
window.wsManager = new WebSocketManager();