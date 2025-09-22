#!/bin/bash

# Configurar el PATH de Flutter
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar si Flutter ya está descargado
if [ ! -d "flutter" ]; then
    echo "Descargando Flutter..."
    curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz | tar xJ
fi

# Configurar Git
git config --global --add safe.directory /vercel/path0/flutter

# Verificar la instalación
echo "Verificando la instalación de Flutter..."
flutter --version

# Limpiar y obtener dependencias
echo "Obteniendo dependencias..."
flutter clean
flutter pub get

# Construir la aplicación
echo "Construyendo la aplicación para web..."
flutter build web --release

# Verificar que el directorio de salida existe
if [ -d "build/web" ]; then
    echo "✅ Construcción completada exitosamente en build/web/"
    echo "📁 Contenido del directorio build/web/:"
    ls -la build/web/
else
    echo "❌ Error: No se pudo encontrar el directorio de salida build/web"
    exit 1
fi
