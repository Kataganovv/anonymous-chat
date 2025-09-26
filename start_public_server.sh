#!/bin/bash

# Скрипт для запуска публичного сервера чата с ngrok

echo "🚀 Запуск публичного сервера анонимного чата..."
echo ""

# Проверяем установлен ли ngrok
if ! command -v ngrok &> /dev/null; then
    echo "⚠️  ngrok не установлен. Устанавливаю..."
    
    # Определяем архитектуру
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
        ARCH="arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    fi
    
    # Скачиваем ngrok
    echo "📦 Загружаю ngrok для $OS-$ARCH..."
    curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-${OS}-${ARCH}.tgz | tar xz
    
    # Делаем исполняемым
    chmod +x ngrok
    
    echo "✅ ngrok установлен!"
    echo ""
fi

# Запускаем локальный сервер в фоне
echo "🌐 Запускаю локальный сервер на порту 8000..."
cd "$(dirname "$0")"
python3 -m http.server 8000 --bind 0.0.0.0 &
SERVER_PID=$!

# Ждем немного пока сервер запустится
sleep 2

echo "🔗 Создаю публичный туннель..."
echo ""

# Запускаем ngrok
if [[ -x "./ngrok" ]]; then
    ./ngrok http 8000 --log=stdout --log-level=info > ngrok.log 2>&1 &
elif command -v ngrok &> /dev/null; then
    ngrok http 8000 --log=stdout --log-level=info > ngrok.log 2>&1 &
fi

NGROK_PID=$!

# Ждем пока ngrok запустится
sleep 3

# Получаем публичную ссылку
echo "⏳ Получаю публичную ссылку..."
PUBLIC_URL=""
for i in {1..10}; do
    PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('proto') == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
")
    if [[ -n "$PUBLIC_URL" ]]; then
        break
    fi
    sleep 1
done

if [[ -n "$PUBLIC_URL" ]]; then
    echo ""
    echo "🎉 Сервер успешно запущен!"
    echo ""
    echo "📱 Публичная ссылка (доступна всем в интернете):"
    echo "   $PUBLIC_URL"
    echo ""
    echo "💻 Локальная ссылка:"
    echo "   http://localhost:8000"
    echo ""
    echo "🔗 QR-код и инструкции:"
    echo "   $PUBLIC_URL/connect.html"
    echo ""
    echo "📊 Панель управления ngrok:"
    echo "   http://localhost:4040"
    echo ""
    echo "⚠️  Внимание: Ссылка будет активна пока работает этот скрипт"
    echo "💡 Для остановки нажмите Ctrl+C"
    echo ""
    
    # Обновляем файл с URL для веб-страницы
    echo "$PUBLIC_URL" > public_url.txt
    
    echo "✅ Готово! Поделитесь ссылкой с друзьями!"
    echo ""
    
    # Ждем завершения
    wait $NGROK_PID
else
    echo "❌ Не удалось получить публичную ссылку"
    echo "💡 Попробуйте:"
    echo "   1. Зарегистрироваться на ngrok.com и получить токен"
    echo "   2. Выполнить: ngrok config add-authtoken YOUR_TOKEN"
    echo "   3. Запустить скрипт снова"
fi

# Очистка при завершении
trap 'kill $SERVER_PID $NGROK_PID 2>/dev/null; rm -f ngrok.log public_url.txt' EXIT