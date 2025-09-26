#!/bin/bash

echo "🚀 Установка ngrok для публичного доступа к чату..."
echo ""

# Проверяем установлен ли Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Homebrew не найден. Устанавливаю..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Добавляем Homebrew в PATH для Apple Silicon Mac
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Устанавливаем ngrok
echo "📥 Устанавливаю ngrok..."
brew install ngrok/ngrok/ngrok

echo ""
echo "✅ ngrok установлен успешно!"
echo ""
echo "🔑 Для получения токена:"
echo "   1. Зайдите на https://ngrok.com/signup"
echo "   2. Зарегистрируйтесь (бесплатно)"
echo "   3. Скопируйте ваш authtoken"
echo "   4. Выполните: ngrok config add-authtoken YOUR_TOKEN"
echo ""
echo "🚀 После этого запустите: ./start_public_server.sh"
echo ""

# Предлагаем открыть сайт ngrok
read -p "Открыть сайт ngrok.com для регистрации? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://ngrok.com/signup"
fi