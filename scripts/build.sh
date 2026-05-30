#!/bin/bash
set -e

echo "Instalando dependências Node.js..."
npm install

echo "Rodando scripts de coleta de dados..."
# Usará a variável de ambiente TRANSPARENCIA_API_KEY do Netlify
node fetch-data.js
node fetch-senadores.js
# Quando o fetch-secretarios for feito no futuro, será adicionado aqui

echo "Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Habilitando Flutter Web..."
flutter config --enable-web

echo "Instalando dependências do Flutter..."
flutter pub get

echo "Compilando para Web..."
flutter build web --release
