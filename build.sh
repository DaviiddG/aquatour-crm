#!/bin/bash

# Configurar el PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar la instalación
flutter --version

# Obtener dependencias
flutter pub get

# Construir la aplicación
flutter build web --release --web-renderer html --csp
