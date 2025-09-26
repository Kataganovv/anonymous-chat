#!/bin/bash

# Скрипт для создания публичного доступа к чату через SSH туннель

PORT=8000
TUNNEL_SERVICE="serveo.net"

echo "🌐 Создание публичного туннеля для анонимного чата..."
echo ""

# Проверяем, запущен ли локальный сервер
if ! curl -s http://localhost:$PORT > /dev/null 2>&1; then
    echo "🚀 Запускаю локальный сервер на порту $PORT..."
    python3 -m http.server $PORT --bind 0.0.0.0 &
    SERVER_PID=$!
    sleep 3
fi

echo "🔗 Создаю публичный туннель через $TUNNEL_SERVICE..."
echo ""
echo "⏳ Ожидание создания туннеля..."

# Создаем туннель через serveo.net
ssh -o StrictHostKeyChecking=no -R 80:localhost:$PORT serveo.net &
TUNNEL_PID=$!

# Ждем немного для установки туннеля
sleep 5

echo ""
echo "✅ Туннель создан!"
echo ""
echo "📱 Публичные ссылки для подключения с любого места:"
echo "   https://[generated-subdomain].serveo.net/"
echo ""
echo "💻 Локальный доступ:"
echo "   http://localhost:$PORT/"
echo ""
echo "📋 Чтобы остановить туннель, нажмите Ctrl+C"
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