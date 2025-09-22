#!/bin/bash

# Configurar el PATH de Flutter
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar si Flutter ya está descargado
if [ ! -d "flutter" ]; then
    echo "Descargando Flutter..."
    curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz | tar xJ
fi

# Configurar Git para evitar el error de propiedad
git config --global --add safe.directory /vercel/path0/flutter

# Verificar la instalación
echo "Verificando la instalación de Flutter..."
flutter --version

# Obtener dependencias
echo "Obteniendo dependencias..."
flutter pub get

# Limpiar build previo si existe
if [ -d "build/web" ]; then
    echo "Limpiando build anterior..."
    rm -rf build/web
fi

# Crear directorio de salida
mkdir -p build/web

# Construir la aplicación
echo "Construyendo la aplicación..."
flutter build web --release --web-renderer html --target lib/main.dart

# Verificar que el directorio de salida existe
if [ ! -d "build/web" ]; then
    echo "Error: No se pudo encontrar el directorio de salida build/web"
    exit 1
fi

echo "¡Construcción completada exitosamente en build/web!"
ls -la build/web/
