#!/bin/bash

# Instalar dependencias del sistema
sudo apt-get update
sudo apt-get install -y curl unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

# Configurar Flutter
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor -v

# Obtener dependencias
flutter pub get

# Construir la aplicación
flutter build web --release --web-renderer html --csp
