#!/bin/bash

# Альтернативный скрипт для создания публичного доступа к чату
# Использует бесплатные туннельные сервисы без регистрации

echo "🚀 Запуск публичного сервера анонимного чата (альтернативный метод)..."
echo ""

# Запускаем локальный сервер в фоне
echo "🌐 Запускаю локальный сервер на порту 8000..."
cd "$(dirname "$0")"
python3 -m http.server 8000 --bind 0.0.0.0 &
SERVER_PID=$!

# Ждем немного пока сервер запустится
sleep 2

echo "🔗 Создаю публичный туннель через serveo.net..."
echo ""

# Создаем туннель через SSH (serveo.net)
ssh -o StrictHostKeyChecking=no -R 80:localhost:8000 serveo.net > serveo.log 2>&1 &
SERVEO_PID=$!

# Ждем пока туннель установится
sleep 5

# Извлекаем URL из лога
PUBLIC_URL=$(grep -o "https://[^[:space:]]*\.serveo\.net" serveo.log | head -1)

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
    echo "⚠️  Внимание: Ссылка будет активна пока работает этот скрипт"
    echo "💡 Для остановки нажмите Ctrl+C"
    echo ""
    
    # Сохраняем URL для веб-страницы
    echo "$PUBLIC_URL" > public_url.txt
    
    echo "✅ Готово! Поделитесь ссылкой с друзьями!"
    echo ""
    echo "🔄 Если ссылка не работает, попробуйте запустить start_public_server.sh"
    echo ""
    
    # Ждем завершения
    wait $SERVEO_PID
else
    echo "❌ Не удалось создать туннель через serveo.net"
    echo ""
    echo "🔄 Попробуем localhost.run..."
    
    # Альтернативный метод через localhost.run
    ssh -o StrictHostKeyChecking=no -R 80:localhost:8000 ssh.localhost.run > localhost_run.log 2>&1 &
    LR_PID=$!
    
    sleep 5
    
    PUBLIC_URL=$(grep -o "https://[^[:space:]]*\.lhr\.life" localhost_run.log | head -1)
    
    if [[ -n "$PUBLIC_URL" ]]; then
        echo ""
        echo "🎉 Сервер запущен через localhost.run!"
        echo ""
        echo "📱 Публичная ссылка:"
        echo "   $PUBLIC_URL"
        echo ""
        echo "$PUBLIC_URL" > public_url.txt
        
        wait $LR_PID
    else
        echo "❌ Не удалось создать публичный доступ"
        echo ""
        echo "💡 Рекомендации:"
        echo "   1. Установите ngrok: brew install ngrok"
        echo "   2. Или используйте локальную сеть: ./start_server.sh"
    fi
fi

# Очистка при завершении
trap 'kill $SERVER_PID $SERVEO_PID $LR_PID 2>/dev/null; rm -f serveo.log localhost_run.log public_url.txt' EXIT