#!/bin/bash

# Скрипт для создания публичного туннеля с помощью Cloudflare Quick Tunnel

PORT=8000
echo "🌐 Создание публичного туннеля через Cloudflare..."
echo ""

# Скачиваем cloudflared если его нет
if ! command -v cloudflared &> /dev/null; then
    echo "📥 Скачиваю cloudflared..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz | tar xz
        chmod +x cloudflared
        CLOUDFLARED_CMD="./cloudflared"
    else
        # Linux
        wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
        chmod +x cloudflared
        CLOUDFLARED_CMD="./cloudflared"
    fi
else
    CLOUDFLARED_CMD="cloudflared"
fi

# Проверяем, запущен ли локальный сервер
if ! curl -s http://localhost:$PORT > /dev/null 2>&1; then
    echo "🚀 Запускаю локальный сервер на порту $PORT..."
    python3 -m http.server $PORT --bind 0.0.0.0 &
    SERVER_PID=$!
    sleep 3
fi

echo "🔗 Создаю публичный туннель через Cloudflare..."
echo ""

# Создаем туннель
$CLOUDFLARED_CMD tunnel --url http://localhost:$PORT &
TUNNEL_PID=$!

echo "⏳ Туннель создается, ссылка появится через несколько секунд..."
echo ""

# Функция для очистки при завершении
cleanup() {
    echo ""
    echo "🛑 Останавливаю сервисы..."
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
    fi
    if [ ! -z "$TUNNEL_PID" ]; then
        kill $TUNNEL_PID 2>/dev/null
    fi
    exit 0
}

trap cleanup INT TERM

# Ожидаем завершения
wait