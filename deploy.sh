#!/bin/bash
set -e

echo "==> Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "==> Versao do Flutter:"
flutter --version

echo "==> Habilitando suporte a web..."
flutter config --enable-web

echo "==> Criando arquivo .env a partir das variaveis de ambiente..."
cat > .env << EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
ENVIRONMENT=production
EOF

echo "==> Instalando dependencias..."
flutter pub get

echo "==> Buildando para web (release)..."
flutter build web --release --web-renderer canvaskit

echo "==> Build concluido!"
