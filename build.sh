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

# Limpiar todo antes de construir
echo "Limpiando proyecto..."
flutter clean

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

# Construir la aplicación con modo release y renderizador HTML
echo "Construyendo la aplicación para web..."
flutter build web \
  --release \
  --web-renderer html \
  --target lib/main.dart \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/ \
  --dart-define=FLUTTER_WEB_USE_SKIA=true

# Verificar que el directorio de salida existe
if [ ! -d "build/web" ]; then
    echo "Error: No se pudo encontrar el directorio de salida build/web"
    exit 1
fi

# Mostrar información del build
echo "\n✅ Construcción completada exitosamente en build/web/"
echo "\n📁 Contenido del directorio build/web/:"
ls -la build/web/

# Verificar archivos críticos
CRITICAL_FILES=("index.html" "main.dart.js" "flutter.js" "manifest.json")
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "build/web/$file" ]; then
        echo "\n⚠️  ¡Advertencia! No se encontró el archivo crítico: $file"
    else
        echo "\n✅ Archivo encontrado: $file"
    fi
done

echo "\n🚀 ¡La aplicación está lista para desplegarse!"
