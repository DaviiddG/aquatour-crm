#!/bin/bash

# Instalar dependencias del sistema
echo "Actualizando el sistema..."
sudo apt-get update
echo "Instalando dependencias..."
sudo apt-get install -y curl unzip xz-utils

# Descargar y configurar Flutter
echo "Descargando Flutter..."
curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz | tar xJ
export PATH="$PATH:`pwd`/flutter/bin"

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
