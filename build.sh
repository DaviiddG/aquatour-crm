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

# Construir la aplicación
echo "Construyendo la aplicación..."
flutter build web --release --web-renderer html

echo "¡Construcción completada exitosamente!"
