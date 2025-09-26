// Конфигурация приложения
const CONFIG = {
    maxMessages: 100,
    maxMessageLength: 500,
    maxNameLength: 20,
    typingTimeout: 3000,
    messageTimeout: 10000,
    colors: [
        '#667eea', '#764ba2', '#f093fb', '#f5576c',
        '#4facfe', '#00f2fe', '#43e97b', '#38f9d7',
        '#ffecd2', '#fcb69f', '#a8edea', '#fed6e3',
        '#ff9a9e', '#fecfef', '#ffeaa7', '#fab1a0'
    ]
};

// Состояние приложения
const state = {
    currentUser: null,
    messages: [],
    isTyping: false,
    typingUsers: new Set(),
    onlineUsers: new Set(),
    socket: null,
    isConnected: false
};

// Генератор случайных имён
const randomNames = [
    'Космический Путешественник', 'Тайный Агент', 'Цифровой Призрак', 'Неизвестный Герой',
    'Виртуальный Друг', 'Анонимный Мудрец', 'Код-Мастер', 'Пиксельный Художник',
    'Звёздный Странник', 'Цифровой Кочевник', 'Битовый Волшебник', 'Кибер-Философ',
    'Сетевой Призрак', 'Алго-Ритм', 'Датаный Детектив', 'Крипто-Исследователь'
];

// Утилиты
const utils = {
    generateId: () => Math.random().toString(36).substr(2, 9),
    
    formatTime: (date) => {
        const now = new Date();
        const diff = now - date;
        
        if (diff < 60000) return 'сейчас';
        if (diff < 3600000) return `${Math.floor(diff / 60000)} мин назад`;
        if (diff < 86400000) return `${Math.floor(diff / 3600000)} ч назад`;
        
        return date.toLocaleTimeString('ru-RU', { 
            hour: '2-digit', 
            minute: '2-digit' 
        });
    },
    
    getRandomColor: () => CONFIG.colors[Math.floor(Math.random() * CONFIG.colors.length)],
    
    getRandomName: () => randomNames[Math.floor(Math.random() * randomNames.length)],
    
    sanitizeText: (text) => {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },
    
    getUserAvatar: (name) => {
        return name.charAt(0).toUpperCase();
    },
    
    showNotification: (message, type = 'success') => {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        document.getElementById('notifications').appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'notificationSlideIn 0.3s ease-out reverse';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
};

// Управление пользователями
const userManager = {
    createUser: (name) => {
        const user = {
            id: utils.generateId(),
            name: name.trim(),
            color: utils.getRandomColor(),
            joinedAt: new Date()
        };
        
        state.currentUser = user;
        localStorage.setItem('chatUser', JSON.stringify(user));
        return user;
    },
    
    loadUser: () => {
        const saved = localStorage.getItem('chatUser');
        if (saved) {
            try {
                state.currentUser = JSON.parse(saved);
                return state.currentUser;
            } catch (e) {
                localStorage.removeItem('chatUser');
            }
        }
        return null;
    },
    
    updateUserDisplay: () => {
        if (state.currentUser) {
            document.getElementById('userName').textContent = state.currentUser.name;
        }
    }
};

// Управление сообщениями
const messageManager = {
    addMessage: (message) => {
        state.messages.push(message);
        
        // Ограничиваем количество сообщений
        if (state.messages.length > CONFIG.maxMessages) {
            state.messages = state.messages.slice(-CONFIG.maxMessages);
        }
        
        messageManager.renderMessage(message);
        messageManager.scrollToBottom();
    },
    
    renderMessage: (message) => {
        const messagesContainer = document.getElementById('chatMessages');
        
        // Удаляем пустое состояние если оно есть
        const emptyState = messagesContainer.querySelector('.empty-state');
        if (emptyState) emptyState.remove();
        
        const messageElement = document.createElement('div');
        
        if (message.type === 'system') {
            messageElement.className = 'message system-message';
            messageElement.innerHTML = `
                <div class="message-text">${utils.sanitizeText(message.text)}</div>
            `;
        } else {
            const isOwn = message.userId === state.currentUser?.id;
            messageElement.className = `message ${isOwn ? 'own' : ''}`;
            
            messageElement.innerHTML = `
                <div class="message-avatar" style="background-color: ${message.color}">
                    ${utils.getUserAvatar(message.author)}
                </div>
                <div class="message-content">
                    <div class="message-header">
                        <span class="message-author">${utils.sanitizeText(message.author)}</span>
                        <span class="message-time">${utils.formatTime(new Date(message.timestamp))}</span>
                    </div>
                    <div class="message-text">${utils.sanitizeText(message.text)}</div>
                </div>
            `;
        }
        
        messagesContainer.appendChild(messageElement);
    },
    
    renderEmptyState: () => {
        const messagesContainer = document.getElementById('chatMessages');
        messagesContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-comments"></i>
                <h3>Добро пожаловать в чат!</h3>
                <p>Пока здесь никого нет. Начните общение первым!</p>
            </div>
        `;
    },
    
    scrollToBottom: () => {
        const messagesContainer = document.getElementById('chatMessages');
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },
    
    sendMessage: (text) => {
        if (!text.trim() || !state.currentUser) return false;
        
        const message = {
            id: utils.generateId(),
            text: text.trim(),
            author: state.currentUser.name,
            userId: state.currentUser.id,
            color: state.currentUser.color,
            timestamp: new Date().toISOString(),
            type: 'user'
        };
        
        // В реальном приложении здесь был бы отправка на сервер
        // Пока добавляем сообщение локально
        messageManager.addMessage(message);
        
        // Симулируем получение сообщения другими пользователями
        setTimeout(() => {
            chatSimulation.simulateResponse();
        }, Math.random() * 3000 + 1000);
        
        return true;
    }
};

// Симуляция чата (для демонстрации)
const chatSimulation = {
    botNames: [
        'Дружелюбный Бот', 'Умный Помощник', 'Веселый Собеседник', 
        'Мудрый Советчик', 'Загадочный Странник'
    ],
    
    responses: [
        'Привет! Как дела?', 'Интересная мысль!', 'Согласен с вами',
        'А что вы об этом думаете?', 'Отличная погода сегодня!',
        'Кто-нибудь смотрел новый фильм?', 'Хорошего дня всем!',
        'Любопытно... 🤔', 'Точно подмечено!', 'А у меня другое мнение',
        'Расскажите подробнее', 'Это напомнило мне одну историю...',
        'Кстати, а вы знали, что...', 'Поддерживаю! 👍'
    ],
    
    simulateResponse: () => {
        if (Math.random() > 0.4) return; // 40% вероятность ответа
        
        const name = chatSimulation.botNames[Math.floor(Math.random() * chatSimulation.botNames.length)];
        const text = chatSimulation.responses[Math.floor(Math.random() * chatSimulation.responses.length)];
        
        const message = {
            id: utils.generateId(),
            text: text,
            author: name,
            userId: utils.generateId(),
            color: utils.getRandomColor(),
            timestamp: new Date().toISOString(),
            type: 'user'
        };
        
        // Показываем индикатор печатания
        typingManager.showTyping(name);
        
        setTimeout(() => {
            typingManager.hideTyping();
            messageManager.addMessage(message);
        }, Math.random() * 2000 + 1000);
    },
    
    simulateUserJoin: () => {
        const name = chatSimulation.botNames[Math.floor(Math.random() * chatSimulation.botNames.length)];
        const message = {
            id: utils.generateId(),
            text: `${name} присоединился к чату`,
            type: 'system',
            timestamp: new Date().toISOString()
        };
        
        messageManager.addMessage(message);
        onlineManager.updateCount(Math.floor(Math.random() * 10) + 1);
    }
};

// Управление индикатором печатания
const typingManager = {
    showTyping: (userName) => {
        state.typingUsers.add(userName);
        typingManager.updateDisplay();
    },
    
    hideTyping: (userName = null) => {
        if (userName) {
            state.typingUsers.delete(userName);
        } else {
            state.typingUsers.clear();
        }
        typingManager.updateDisplay();
    },
    
    updateDisplay: () => {
        const indicator = document.getElementById('typingIndicator');
        
        if (state.typingUsers.size > 0) {
            const names = Array.from(state.typingUsers).slice(0, 2);
            let text = names.join(', ') + ' печатает';
            if (state.typingUsers.size > 2) {
                text += ` и ещё ${state.typingUsers.size - 2}`;
            }
            text += '...';
            
            indicator.querySelector('.typing-text').textContent = text;
            indicator.classList.add('show');
        } else {
            indicator.classList.remove('show');
        }
    }
};

// Управление онлайн-пользователями
const onlineManager = {
    updateCount: (count) => {
        document.getElementById('onlineCount').textContent = count;
    }
};

// UI контроллеры
const uiController = {
    init: () => {
        uiController.setupEventListeners();
        uiController.setupEmojiPicker();
        uiController.setupNameModal();
        
        // Проверяем сохранённого пользователя
        if (!userManager.loadUser()) {
            uiController.showNameModal();
        } else {
            userManager.updateUserDisplay();
            messageManager.renderEmptyState();
            
            // Симулируем активность
            setTimeout(() => {
                chatSimulation.simulateUserJoin();
            }, 2000);
        }
    },
    
    setupEventListeners: () => {
        const messageInput = document.getElementById('messageInput');
        const sendBtn = document.getElementById('sendBtn');
        
        // Отправка сообщения
        sendBtn.addEventListener('click', uiController.handleSendMessage);
        messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                uiController.handleSendMessage();
            }
        });
        
        // Индикатор печатания
        let typingTimeout;
        messageInput.addEventListener('input', () => {
            if (!state.isTyping) {
                state.isTyping = true;
                // В реальном приложении здесь была бы отправка события на сервер
            }
            
            clearTimeout(typingTimeout);
            typingTimeout = setTimeout(() => {
                state.isTyping = false;
            }, CONFIG.typingTimeout);
        });
        
        // Закрытие эмодзи-пикера при клике вне его
        document.addEventListener('click', (e) => {
            const emojiPicker = document.getElementById('emojiPicker');
            const emojiBtn = document.getElementById('emojiBtn');
            
            if (!emojiPicker.contains(e.target) && !emojiBtn.contains(e.target)) {
                emojiPicker.classList.remove('show');
            }
        });
    },
    
    setupEmojiPicker: () => {
        const emojiBtn = document.getElementById('emojiBtn');
        const emojiPicker = document.getElementById('emojiPicker');
        const messageInput = document.getElementById('messageInput');
        
        emojiBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            emojiPicker.classList.toggle('show');
        });
        
        // Добавление эмодзи в сообщение
        emojiPicker.addEventListener('click', (e) => {
            if (e.target.classList.contains('emoji')) {
                const emoji = e.target.textContent;
                const start = messageInput.selectionStart;
                const end = messageInput.selectionEnd;
                const text = messageInput.value;
                
                messageInput.value = text.substring(0, start) + emoji + text.substring(end);
                messageInput.setSelectionRange(start + emoji.length, start + emoji.length);
                messageInput.focus();
                
                emojiPicker.classList.remove('show');
            }
        });
    },
    
    setupNameModal: () => {
        const modal = document.getElementById('nameModal');
        const nameInput = document.getElementById('nameInput');
        const joinBtn = document.getElementById('joinChatBtn');
        const nameSuggestions = document.getElementById('nameSuggestions');
        
        // Генерируем предложения имён
        for (let i = 0; i < 6; i++) {
            const suggestion = document.createElement('span');
            suggestion.className = 'name-suggestion';
            suggestion.textContent = utils.getRandomName();
            suggestion.addEventListener('click', () => {
                nameInput.value = suggestion.textContent;
            });
            nameSuggestions.appendChild(suggestion);
        }
        
        // Обработка входа в чат
        const joinChat = () => {
            const name = nameInput.value.trim();
            if (name.length < 2) {
                utils.showNotification('Имя должно содержать минимум 2 символа', 'error');
                return;
            }
            if (name.length > CONFIG.maxNameLength) {
                utils.showNotification(`Имя не должно превышать ${CONFIG.maxNameLength} символов`, 'error');
                return;
            }
            
            userManager.createUser(name);
            userManager.updateUserDisplay();
            uiController.hideNameModal();
            
            // Добавляем системное сообщение о входе
            const joinMessage = {
                id: utils.generateId(),
                text: `${name} присоединился к чату`,
                type: 'system',
                timestamp: new Date().toISOString()
            };
            
            messageManager.addMessage(joinMessage);
            utils.showNotification('Добро пожаловать в чат!');
            
            // Симулируем активность
            setTimeout(() => {
                chatSimulation.simulateUserJoin();
            }, 3000);
        };
        
        joinBtn.addEventListener('click', joinChat);
        nameInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                joinChat();
            }
        });
        
        // Фокус на поле ввода при открытии модального окна
        setTimeout(() => nameInput.focus(), 100);
    },
    
    showNameModal: () => {
        document.getElementById('nameModal').style.display = 'flex';
    },
    
    hideNameModal: () => {
        document.getElementById('nameModal').style.display = 'none';
    },
    
    handleSendMessage: () => {
        const messageInput = document.getElementById('messageInput');
        const text = messageInput.value.trim();
        
        if (!text) return;
        
        if (text.length > CONFIG.maxMessageLength) {
            utils.showNotification(`Сообщение не должно превышать ${CONFIG.maxMessageLength} символов`, 'error');
            return;
        }
        
        if (messageManager.sendMessage(text)) {
            messageInput.value = '';
            document.getElementById('emojiPicker').classList.remove('show');
        }
    }
};

// Инициализация приложения
document.addEventListener('DOMContentLoaded', () => {
    uiController.init();
    
    // Обновляем счётчик онлайн с случайным числом
    onlineManager.updateCount(Math.floor(Math.random() * 5) + 1);
    
    // Периодически обновляем время в сообщениях
    setInterval(() => {
        document.querySelectorAll('.message-time').forEach(timeElement => {
            const message = state.messages.find(m => 
                timeElement.closest('.message')?.querySelector('.message-author')?.textContent === m.author
            );
            if (message) {
                timeElement.textContent = utils.formatTime(new Date(message.timestamp));
            }
        });
    }, 60000);
    
    // Периодически симулируем активность
    setInterval(() => {
        if (Math.random() > 0.7) {
            chatSimulation.simulateResponse();
        }
    }, 10000);
});

// Обработка ошибок
window.addEventListener('error', (e) => {
    console.error('Ошибка приложения:', e.error);
    utils.showNotification('Произошла ошибка. Попробуйте обновить страницу.', 'error');
});

// Экспорт для использования в других файлах (если нужно)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        CONFIG,
        state,
        utils,
        userManager,
        messageManager,
        uiController
    };
}