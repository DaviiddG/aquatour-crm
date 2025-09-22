#!/bin/bash

# Configurar el PATH de Flutter
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar si Flutter ya está descargado
if [ ! -d "flutter" ]; then
    echo "Descargando Flutter..."
    curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz | tar xJ
fi

# Configurar Git
flutter --version
flutter clean
flutter pub get

# Construir la aplicación
echo "Construyendo la aplicación..."
flutter build web --release --web-renderer html

echo "✅ Construcción completada"
