@echo off
REM Configuración de Git para AquaTour CRM

echo Configurando Git...

REM Configurar nombre y email
git config --global user.name "Oscar"
git config --global user.email "oscar@example.com"

REM Inicializar repositorio si no existe
if not exist .git (
    git init
)

REM Añadir archivos
git add .

REM Hacer commit inicial
git commit -m "Versión inicial del proyecto AquaTour CRM

Características implementadas:
- Sistema de login funcional con usuarios reales
- Gestión completa de usuarios con roles y permisos
- Sistema de roles (Empleado, Administrador, Superadministrador)
- Control de permisos basado en roles
- Interfaz moderna y responsiva
- Base de datos local (LocalStorage)"

REM Crear rama develop
git checkout -b develop
git checkout main

echo Configuración completada!
echo.
echo Próximos pasos:
echo 1. Crear repositorio en GitHub
echo 2. Ejecutar: git remote add origin https://github.com/tu-usuario/aquatour-crm.git
echo 3. Ejecutar: git push -u origin main
echo 4. Ejecutar: git push -u origin develop

pause
