#!/bin/bash

# Быстрый запуск публичного чата без регистрации
# Использует бесплатные SSH туннели

echo "🚀 Быстрый запуск публичного чата..."
echo "💡 Этот метод не требует регистрации!"
echo ""

cd "$(dirname "$0")"

# Запускаем локальный сервер
echo "🌐 Запуск локального сервера..."
python3 -m http.server 8000 --bind 127.0.0.1 &
SERVER_PID=$!

sleep 2

echo "🔗 Создание публичного туннеля..."
echo "⏳ Пожалуйста, подождите 10-15 секунд..."
echo ""

# Используем SSH туннель через serveo.net
timeout 15s ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -T -R 80:localhost:8000 serveo.net 2>/dev/null | while read line; do
    if [[ $line == *"Forwarding HTTP traffic from"* ]]; then
        PUBLIC_URL=$(echo "$line" | grep -o "https://[^[:space:]]*")
        if [[ -n "$PUBLIC_URL" ]]; then
            echo "🎉 Публичная ссылка создана!"
            echo ""
            echo "📱 Поделитесь этой ссылкой с друзьями:"
            echo "   $PUBLIC_URL"
            echo ""
            echo "🔗 QR-код и инструкции:"
            echo "   $PUBLIC_URL/connect.html"
            echo ""
            echo "💻 Локальный доступ:"
            echo "   http://localhost:8000"
            echo ""
            
            # Сохраняем URL
            echo "$PUBLIC_URL" > public_url.txt
            
            # Открываем локальную страницу
            echo "🌐 Открываю страницу подключения..."
            sleep 1
            open "http://localhost:8000/connect.html"
            
            echo ""
            echo "✅ Готово! Чат доступен публично!"
            echo "⚠️  Для остановки нажмите Ctrl+C"
            echo ""
            break
        fi
    fi
done &

TUNNEL_PID=$!

# Альтернативный способ получения ссылки
sleep 8
if [[ ! -f "public_url.txt" ]]; then
    echo "🔄 Попытка альтернативного подключения..."
    
    # Пробуем localhost.run
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -R 80:localhost:8000 nokey@localhost.run 2>&1 | grep -o "https://[^[:space:]]*\.lhr\.life" | head -1 > public_url.txt &
    
    sleep 5
    
    if [[ -s "public_url.txt" ]]; then
        PUBLIC_URL=$(cat public_url.txt)
        echo "🎉 Альтернативная ссылка создана!"
        echo "📱 Публичная ссылка: $PUBLIC_URL"
        echo ""
        open "http://localhost:8000/connect.html"
    else
        echo "⚠️  Не удалось создать публичный туннель"
        echo "💡 Попробуйте:"
        echo "   1. ./install_ngrok.sh - для установки ngrok"
        echo "   2. ./start_server.sh - для локальной сети"
        echo ""
        
        # Показываем локальную информацию
        LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
        echo "🏠 Локальная сеть:"
        echo "   http://$LOCAL_IP:8000"
        open "http://localhost:8000/connect.html"
    fi
fi

# Ожидаем завершения
echo "💡 Нажмите Ctrl+C для остановки сервера"
wait $SERVER_PID

# Очистка
trap 'kill $SERVER_PID $TUNNEL_PID 2>/dev/null; rm -f public_url.txt' EXIT