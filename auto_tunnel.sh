#!/bin/bash

# Автоматический скрипт для создания публичного туннеля с QR-кодом
# Поддерживает локальные туннели без установки дополнительного ПО

PORT=8000
CHAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌍 Создание публичного доступа к анонимному чату..."
echo ""

# Функция для генерации случайного поддомена
generate_subdomain() {
    echo "chat-$(date +%s | tail -c 6)"
}

# Проверяем, запущен ли локальный сервер
check_local_server() {
    if curl -s http://localhost:$PORT > /dev/null 2>&1; then
        echo "✅ Локальный сервер уже запущен"
        return 0
    else
        echo "🚀 Запускаю локальный сервер..."
        cd "$CHAT_DIR"
        python3 -m http.server $PORT --bind 0.0.0.0 > /dev/null 2>&1 &
        SERVER_PID=$!
        sleep 3
        return 1
    fi
}

# Создание туннеля через localhost.run
create_localhost_run_tunnel() {
    echo "🔗 Создание туннеля через localhost.run..."
    
    # Запускаем туннель в фоне и перехватываем вывод
    ssh -o StrictHostKeyChecking=no -R 80:localhost:$PORT localhost.run 2>&1 | while IFS= read -r line; do
        echo "$line"
        # Ищем URL в выводе
        if [[ $line == *"tunneled with tls termination"* ]] && [[ $line == *"https://"* ]]; then
            PUBLIC_URL=$(echo "$line" | grep -oE 'https://[^[:space:]]+')
            echo "$PUBLIC_URL" > /tmp/tunnel_url.txt
            echo ""
            echo "🎉 Туннель создан успешно!"
            echo "🔗 Публичная ссылка: $PUBLIC_URL"
            echo ""
            
            # Генерируем QR-код в ASCII
            if command -v qrencode >/dev/null 2>&1; then
                echo "📱 QR-код:"
                qrencode -t ANSI "$PUBLIC_URL"
            else
                echo "📱 Для генерации QR-кода установите qrencode:"
                echo "   brew install qrencode"
            fi
            
            echo ""
            echo "📋 Скопируйте и отправьте эту ссылку друзьям:"
            echo "   $PUBLIC_URL"
            echo ""
            
            break
        fi
    done &
    
    TUNNEL_PID=$!
}

# Создание туннеля через serveo.net
create_serveo_tunnel() {
    echo "🔗 Создание туннеля через serveo.net..."
    
    SUBDOMAIN=$(generate_subdomain)
    PUBLIC_URL="https://$SUBDOMAIN.serveo.net"
    
    echo "🌐 Попытка создать туннель: $PUBLIC_URL"
    
    # Запускаем туннель
    ssh -o StrictHostKeyChecking=no -R $SUBDOMAIN:80:localhost:$PORT serveo.net > /dev/null 2>&1 &
    TUNNEL_PID=$!
    
    # Ждем немного и проверяем доступность
    sleep 5
    
    if curl -s "$PUBLIC_URL" > /dev/null 2>&1; then
        echo "$PUBLIC_URL" > /tmp/tunnel_url.txt
        echo ""
        echo "🎉 Туннель создан успешно!"
        echo "🔗 Публичная ссылка: $PUBLIC_URL"
        echo ""
        
        # Генерируем QR-код в ASCII
        if command -v qrencode >/dev/null 2>&1; then
            echo "📱 QR-код:"
            qrencode -t ANSI "$PUBLIC_URL"
        fi
        
        echo ""
        echo "📋 Скопируйте и отправьте эту ссылку друзьям:"
        echo "   $PUBLIC_URL"
        echo ""
    else
        echo "❌ Не удалось создать туннель через serveo.net"
        return 1
    fi
}

# Создание туннеля без внешних зависимостей
create_simple_tunnel() {
    echo "🔗 Создание простого туннеля..."
    
    # Используем ngrok альтернативу - bore
    if ! command -v bore >/dev/null 2>&1; then
        echo "📥 Скачиваю bore (простая альтернатива ngrok)..."
        
        # Определяем архитектуру
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ $(uname -m) == "arm64" ]]; then
                BORE_URL="https://github.com/ekzhang/bore/releases/latest/download/bore-v0.5.0-aarch64-apple-darwin.tar.gz"
            else
                BORE_URL="https://github.com/ekzhang/bore/releases/latest/download/bore-v0.5.0-x86_64-apple-darwin.tar.gz"
            fi
        else
            BORE_URL="https://github.com/ekzhang/bore/releases/latest/download/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz"
        fi
        
        curl -L "$BORE_URL" | tar xz > /dev/null 2>&1
        chmod +x bore
    fi
    
    # Запускаем bore туннель
    if [ -f "./bore" ] || command -v bore >/dev/null 2>&1; then
        echo "🚀 Запускаю bore туннель..."
        
        BORE_CMD="bore"
        if [ -f "./bore" ]; then
            BORE_CMD="./bore"
        fi
        
        # Запускаем bore и получаем URL
        $BORE_CMD local $PORT --to bore.pub > /tmp/bore_output.txt 2>&1 &
        TUNNEL_PID=$!
        
        sleep 3
        
        # Извлекаем URL из вывода
        if [ -f "/tmp/bore_output.txt" ]; then
            PUBLIC_URL=$(grep -o 'http://[^[:space:]]*' /tmp/bore_output.txt | head -1)
            if [ ! -z "$PUBLIC_URL" ]; then
                echo "$PUBLIC_URL" > /tmp/tunnel_url.txt
                echo ""
                echo "🎉 Туннель создан успешно!"
                echo "🔗 Публичная ссылка: $PUBLIC_URL"
                echo ""
                
                # Генерируем QR-код
                if command -v qrencode >/dev/null 2>&1; then
                    echo "📱 QR-код:"
                    qrencode -t ANSI "$PUBLIC_URL"
                fi
                
                echo ""
                echo "📋 Скопируйте и отправьте эту ссылку друзьям:"
                echo "   $PUBLIC_URL"
                echo ""
            fi
        fi
    else
        echo "❌ Не удалось скачать bore"
        return 1
    fi
}

# Функция очистки
cleanup() {
    echo ""
    echo "🛑 Останавливаю сервисы..."
    
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
    fi
    
    if [ ! -z "$TUNNEL_PID" ]; then
        kill $TUNNEL_PID 2>/dev/null
    fi
    
    # Очищаем временные файлы
    rm -f /tmp/tunnel_url.txt /tmp/bore_output.txt
    
    echo "✅ Готово!"
    exit 0
}

# Устанавливаем обработчик сигналов
trap cleanup INT TERM

# Основная логика
echo "📋 Доступные варианты создания публичного туннеля:"
echo "   1. localhost.run (SSH туннель)"
echo "   2. serveo.net (SSH туннель с поддоменом)"
echo "   3. bore.pub (простой HTTP туннель)"
echo ""

read -p "Выберите вариант (1-3) или нажмите Enter для автоматического выбора: " choice

# Проверяем локальный сервер
check_local_server

case $choice in
    1)
        create_localhost_run_tunnel
        ;;
    2)
        create_serveo_tunnel
        ;;
    3)
        create_simple_tunnel
        ;;
    *)
        echo "🤖 Автоматический выбор лучшего варианта..."
        
        # Пробуем варианты по порядку
        if create_simple_tunnel; then
            echo "✅ Используется bore.pub"
        elif create_serveo_tunnel; then
            echo "✅ Используется serveo.net"
        elif create_localhost_run_tunnel; then
            echo "✅ Используется localhost.run"
        else
            echo "❌ Не удалось создать туннель"
            echo ""
            echo "🔧 Попробуйте вручную:"
            echo "   ssh -R 80:localhost:$PORT localhost.run"
            echo "   или"
            echo "   ssh -R 80:localhost:$PORT serveo.net"
            exit 1
        fi
        ;;
esac

echo ""
echo "🎯 Туннель активен! Нажмите Ctrl+C для остановки..."
echo ""

# Показываем статистику подключений
echo "📊 Мониторинг подключений:"
tail -f /dev/null