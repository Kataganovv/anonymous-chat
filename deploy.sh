#!/bin/bash

# Автоматический скрипт деплоя на GitHub Pages
# Email: katagan.99@gmail.com

echo "🚀 Автоматический деплой анонимного чата"
echo "📧 Аккаунт: katagan.99@gmail.com"
echo "🌐 Финальный URL: https://katagan99.github.io/anonymous-chat/"
echo ""

# Проверяем наличие Git
if ! command -v git &> /dev/null; then
    echo "❌ Git не установлен."
    echo "💡 Установите Git командой: brew install git"
    exit 1
fi

# Настройка Git
echo "⚙️  Настройка Git..."
git config --global user.email "katagan.99@gmail.com"
git config --global user.name "katagan99"

# Переходим в директорию проекта
cd "$(dirname "$0")"

# Очищаем Git если уже инициализирован
if [ -d ".git" ]; then
    echo "🔄 Очищаю предыдущую Git конфигурацию..."
    rm -rf .git
fi

# Создаем .gitignore
echo "📝 Создаю .gitignore..."
cat > .gitignore << EOF
# Логи и временные файлы
*.log
*.tmp
.DS_Store
Thumbs.db

# Исполняемые файлы
ngrok
*.exe

# Секретные файлы
.env
config.json

# Папки
node_modules/
dist/
build/
EOF

# Инициализируем Git
echo "🔧 Инициализация Git репозитория..."
git init

# Добавляем файлы
echo "📁 Добавляю файлы в репозиторий..."
git add .

# Создаем коммит
echo "💾 Создаю коммит..."
git commit -m "🎉 Initial deploy: Anonymous Chat App

✨ Features:
- Anonymous chat with random usernames
- Real-time message simulation
- Emoji support
- Responsive design
- QR code generator
- Multiple deployment options

🚀 Ready for GitHub Pages deployment
📧 Contact: katagan.99@gmail.com"

# Создаем README для GitHub
echo "📖 Создаю README для GitHub..."
cat > README.md << EOF
# 💬 Анонимный чат

Современное веб-приложение для анонимного общения с поддержкой Flutter Flow.

## 🌟 Возможности

- 🎭 Анонимные псевдонимы или случайные имена
- ⚡ Симуляция реального времени
- 😀 Поддержка эмодзи
- 📱 Адаптивный дизайн
- 📊 QR-код генератор
- 🌐 Несколько способов деплоя

## 🚀 Демо

Посетите: [https://katagan99.github.io/anonymous-chat/](https://katagan99.github.io/anonymous-chat/)

## 📱 Использование

1. Откройте ссылку в браузере
2. Выберите псевдоним или используйте случайное имя
3. Начните общение!

## 🔧 Интеграция с Flutter Flow

Этот чат можно легко интегрировать в Flutter Flow через WebView виджет.

## 📧 Контакт

Email: katagan.99@gmail.com

## 📄 Лицензия

MIT License
EOF

# Добавляем README
git add README.md
git commit --amend -m "🎉 Initial deploy: Anonymous Chat App

✨ Features:
- Anonymous chat with random usernames  
- Real-time message simulation
- Emoji support
- Responsive design
- QR code generator
- Multiple deployment options

🚀 Ready for GitHub Pages deployment
📧 Contact: katagan.99@gmail.com"

echo ""
echo "🔗 Подключение к GitHub..."

# Добавляем remote
git remote add origin https://github.com/katagan99/anonymous-chat.git

# Переименовываем ветку
git branch -M main

echo ""
echo "📤 Загружаем проект на GitHub..."
echo "⚠️  Если репозиторий не существует, создайте его на github.com"
echo ""

# Пушим на GitHub
if git push -u origin main; then
    echo ""
    echo "🎉 Успешно загружено на GitHub!"
    echo ""
    echo "🔧 Следующие шаги:"
    echo "1. Зайдите на https://github.com/katagan99/anonymous-chat"
    echo "2. Перейдите в Settings → Pages"
    echo "3. Выберите Source: Deploy from a branch"
    echo "4. Выберите Branch: main"
    echo "5. Нажмите Save"
    echo ""
    echo "🌐 Ваш чат будет доступен по адресу:"
    echo "   https://katagan99.github.io/anonymous-chat/"
    echo ""
    echo "⏰ Активация GitHub Pages занимает 5-10 минут"
    
    # Пытаемся открыть GitHub
    if command -v open &> /dev/null; then
        read -p "Открыть GitHub в браузере? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "https://github.com/katagan99/anonymous-chat"
        fi
    fi
    
else
    echo ""
    echo "⚠️  Возможные проблемы:"
    echo "1. Репозиторий не существует на GitHub"
    echo "2. Нет прав доступа"
    echo "3. Проблемы с аутентификацией"
    echo ""
    echo "💡 Решения:"
    echo "1. Создайте репозиторий: https://github.com/new"
    echo "   - Название: anonymous-chat"
    echo "   - Владелец: katagan99"
    echo "2. Настройте SSH ключи или Personal Access Token"
    echo "3. Попробуйте снова: git push -u origin main"
fi

echo ""
echo "📚 Дополнительные ресурсы:"
echo "- Netlify: https://netlify.com (drag & drop деплой)"  
echo "- Vercel: https://vercel.com (автоматический деплой)"
echo "- Firebase: https://firebase.google.com (Google хостинг)"