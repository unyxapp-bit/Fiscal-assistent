#!/bin/bash
set -e

echo "==> Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter

# Variaveis necessarias para Flutter nao reclamar de root
export PATH="$PATH:/tmp/flutter/bin"
export HOME=/tmp/flutter-home
export USER=vercel_build
export PUB_CACHE=/tmp/pub-cache
mkdir -p /tmp/flutter-home
mkdir -p /tmp/pub-cache

echo "==> Versao do Flutter:"
flutter --version --suppress-analytics

echo "==> Habilitando suporte a web..."
flutter config --enable-web --suppress-analytics

echo "==> Criando arquivo .env..."
cat > .env << EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
ENVIRONMENT=production
EOF

echo "==> Instalando dependencias..."
flutter pub get --suppress-analytics

echo "==> Buildando para web (release)..."
flutter build web --release --web-renderer canvaskit --suppress-analytics

echo "==> Build concluido!"
