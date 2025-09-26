#!/bin/bash

# Получаем IP-адрес компьютера в локальной сети
IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
PORT=8000

echo "🚀 Запуск сервера анонимного чата..."
echo ""
echo "📱 Для подключения с телефона используйте:"
echo "   http://$IP_ADDRESS:$PORT/"
echo ""
echo "💻 Для подключения с компьютера:"
echo "   http://localhost:$PORT/"
echo ""
echo "🔗 Страница с QR-кодом:"
echo "   http://$IP_ADDRESS:$PORT/connect.html"
echo ""
echo "⚠️  Убедитесь, что все устройства подключены к одной Wi-Fi сети"
echo ""

# Запускаем сервер
cd "$(dirname "$0")"
python3 -m http.server $PORT --bind 0.0.0.0