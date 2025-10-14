# Documentación Técnica - Despliegue y CI/CD

**Proyecto:** Aquatour CRM  
**Versión:** 1.0.0  
**Última actualización:** Octubre 2025  

---

## Tabla de Contenidos

1. [Arquitectura de Despliegue](#arquitectura-de-despliegue)
2. [Frontend - Vercel](#frontend---vercel)
3. [Backend - Clever Cloud](#backend---clever-cloud)
4. [Base de Datos - Clever Cloud MySQL](#base-de-datos---clever-cloud-mysql)
5. [CI/CD con GitHub Actions](#cicd-con-github-actions)
6. [Variables de Entorno](#variables-de-entorno)
7. [Dominios y URLs](#dominios-y-urls)
8. [Monitoreo y Logs](#monitoreo-y-logs)
9. [Troubleshooting](#troubleshooting)
10. [Procedimientos de Despliegue](#procedimientos-de-despliegue)

---

## Arquitectura de Despliegue

```
┌─────────────────────────────────────────────────────────┐
│                    USUARIOS FINALES                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              VERCEL CDN (Edge Network)                  │
│         https://tour-crm.vercel.app                     │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Flutter Web (Static Files)             │    │
│  │  - HTML, CSS, JavaScript                       │    │
│  │  - Assets (imágenes, fuentes)                  │    │
│  │  - Service Worker (PWA)                        │    │
│  └────────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ HTTPS/REST API
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              CLEVER CLOUD (Backend)                     │
│  https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374      │
│              .cleverapps.io/api                         │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Node.js + Express Server               │    │
│  │  - API REST endpoints                          │    │
│  │  - Autenticación                               │    │
│  │  - Lógica de negocio                           │    │
│  └────────────────┬───────────────────────────────┘    │
└────────────────────┼────────────────────────────────────┘
                     │
                     │ MySQL Protocol
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         CLEVER CLOUD MySQL (Base de Datos)              │
│  bxxx-mysql.services.clever-cloud.com:3306              │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         MySQL 8.0 Database                     │    │
│  │  - Usuarios, Clientes, Reservas                │    │
│  │  - Cotizaciones, Pagos                         │    │
│  │  - Destinos, Paquetes                          │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              GITHUB (Control de Versiones)              │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         GitHub Actions (CI/CD)                 │    │
│  │  - Build automático                            │    │
│  │  - Deploy a Vercel                             │    │
│  │  - Tests (futuro)                              │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Frontend - Vercel

### Configuración de Vercel

**Plataforma:** Vercel  
**Plan:** Hobby (Gratuito)  
**URL de Producción:** `https://tour-crm.vercel.app`  
**Framework:** Flutter Web (Custom Build)

### Archivo de Configuración

**`vercel.json`:**
```json
{
  "version": 2,
  "buildCommand": "chmod +x build.sh && ./build.sh",
  "outputDirectory": "build/web",
  "framework": null
}
```

**Explicación:**
- `version: 2` - Versión de la configuración de Vercel
- `buildCommand` - Script personalizado de construcción
- `outputDirectory` - Directorio con archivos estáticos generados
- `framework: null` - Desactiva detección automática de framework

### Script de Build

**`build.sh`:**
```bash
#!/bin/bash

# Configurar el PATH de Flutter
export PATH="$PATH:`pwd`/flutter/bin"

# Descargar Flutter si no existe
if [ ! -d "flutter" ]; then
    echo "Descargando Flutter..."
    curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz | tar xJ
fi

# Configurar Git
git config --global --add safe.directory /vercel/path0/flutter

# Verificar instalación
flutter --version

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Construir aplicación
flutter build web --release

# Verificar salida
if [ -d "build/web" ]; then
    echo "✅ Construcción completada"
    ls -la build/web/
else
    echo "❌ Error en construcción"
    exit 1
fi
```

**Proceso de Build:**
1. Descarga Flutter SDK (si no existe)
2. Configura Git para evitar errores de permisos
3. Limpia build anterior
4. Obtiene dependencias de `pubspec.yaml`
5. Compila Flutter Web en modo release
6. Verifica que la salida existe

### Variables de Entorno en Vercel

Configuradas en el dashboard de Vercel:

```
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
APP_ENV=production
DEBUG=false
```

### Características de Vercel

- **CDN Global:** Distribución en edge locations worldwide
- **HTTPS automático:** Certificado SSL gratuito
- **Deploy Previews:** URL única para cada PR
- **Rollback:** Reversión a versiones anteriores con un clic
- **Analytics:** Métricas de uso (opcional)
- **Bandwidth:** 100GB/mes en plan gratuito

### Proceso de Despliegue en Vercel

1. Push a rama `main` en GitHub
2. GitHub Actions ejecuta workflow
3. Vercel CLI despliega automáticamente
4. Build se ejecuta en servidor de Vercel
5. Archivos estáticos se distribuyen en CDN
6. URL de producción se actualiza

**Tiempo promedio de deploy:** 3-5 minutos

---

## Backend - Clever Cloud

### Configuración de Clever Cloud

**Plataforma:** Clever Cloud  
**Plan:** Node.js (Gratuito)  
**Región:** EU (Europa)  
**URL:** `https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io`

### Configuración de la Aplicación

**Runtime:** Node.js 18  
**Package Manager:** npm  
**Build Command:** `npm install`  
**Start Command:** `npm start`  
**Port:** 8080 (automático)

### Variables de Entorno en Clever Cloud

Configuradas en el panel de Clever Cloud:

```bash
# Base de datos
DB_HOST=bxxx-mysql.services.clever-cloud.com
DB_PORT=3306
DB_USER=uxxx
DB_PASSWORD=xxx
DB_NAME=bxxx

# Servidor
PORT=8080
NODE_ENV=production

# CORS
CORS_ORIGIN=https://tour-crm.vercel.app,http://localhost:3000

# API
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
```

### Características de Clever Cloud

- **Auto-scaling:** Escala automáticamente según demanda
- **Zero-downtime deploys:** Sin interrupciones
- **Logs en tiempo real:** Acceso a logs del servidor
- **Métricas:** CPU, RAM, requests
- **Backups automáticos:** Base de datos
- **Git deployment:** Deploy con `git push`

### Proceso de Despliegue en Clever Cloud

**Opción 1: Git Push**
```bash
git remote add clever git+ssh://git@push-n2-par-clevercloud-customers.services.clever-cloud.com/app_xxx.git
git push clever main
```

**Opción 2: GitHub Integration**
- Conectar repositorio de GitHub
- Auto-deploy en cada push a `main`

**Proceso:**
1. Clever Cloud detecta cambios
2. Ejecuta `npm install`
3. Inicia servidor con `npm start`
4. Health check en `/api/health`
5. Redirige tráfico a nueva versión

**Tiempo promedio de deploy:** 2-3 minutos

---

## Base de Datos - Clever Cloud MySQL

### Configuración de MySQL

**Plataforma:** Clever Cloud MySQL  
**Plan:** DEV (Gratuito)  
**Versión:** MySQL 8.0  
**Región:** EU (Europa)

### Límites del Plan Gratuito

- **Almacenamiento:** 256 MB
- **Conexiones simultáneas:** 5 máximo
- **Backups:** Diarios con retención de 7 días
- **RAM:** Compartida

### Conexión a la Base de Datos

**Desde aplicación Node.js:**
```javascript
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  connectionLimit: 3,  // Dejar margen para otras conexiones
});
```

**Desde cliente MySQL:**
```bash
mysql -h bxxx-mysql.services.clever-cloud.com \
      -P 3306 \
      -u uxxx \
      -p \
      bxxx
```

### Backups

**Automáticos:**
- Diarios a las 02:00 UTC
- Retención de 7 días
- Acceso desde panel de Clever Cloud

**Manuales:**
```bash
# Exportar base de datos
mysqldump -h HOST -u USER -p DATABASE > backup.sql

# Importar base de datos
mysql -h HOST -u USER -p DATABASE < backup.sql
```

---

## CI/CD con GitHub Actions

### Workflow de Despliegue

**Archivo:** `.github/workflows/deploy.yml`

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install Vercel CLI
        run: npm install --global vercel@latest

      - name: Deploy to Vercel
        run: |
          vercel --prod --token ${{ secrets.VERCEL_TOKEN }} --confirm
        working-directory: ./
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
          API_BASE_URL: ${{ secrets.API_BASE_URL }}
```

### Triggers del Workflow

1. **Push a main:** Despliegue automático
2. **Manual dispatch:** Desde GitHub Actions UI

### Secretos de GitHub

Configurados en Settings → Secrets and variables → Actions:

```
VERCEL_TOKEN          - Token de autenticación de Vercel
VERCEL_ORG_ID         - ID de organización de Vercel
VERCEL_PROJECT_ID     - ID del proyecto en Vercel
API_BASE_URL          - URL del backend
```

### Obtener Tokens de Vercel

```bash
# Instalar Vercel CLI
npm install -g vercel

# Login
vercel login

# Obtener tokens
vercel whoami
vercel project ls
```

### Flujo Completo de CI/CD

```
Developer
    ↓
git commit & push to main
    ↓
GitHub detecta push
    ↓
GitHub Actions inicia workflow
    ↓
Checkout código
    ↓
Instala Vercel CLI
    ↓
Ejecuta vercel --prod
    ↓
Vercel ejecuta build.sh
    ↓
Flutter build web --release
    ↓
Archivos a CDN de Vercel
    ↓
Deploy completado
    ↓
Notificación en GitHub
```

**Tiempo total:** 3-5 minutos

---

## Variables de Entorno

### Frontend (.env)

```bash
# Desarrollo local
API_BASE_URL=http://localhost:8080/api
APP_ENV=development
DEBUG=true
```

```bash
# Producción (Vercel)
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
APP_ENV=production
DEBUG=false
```

### Backend (.env)

```bash
# Base de datos
DB_HOST=bxxx-mysql.services.clever-cloud.com
DB_PORT=3306
DB_USER=uxxx
DB_PASSWORD=xxx
DB_NAME=bxxx

# Servidor
PORT=8080
NODE_ENV=production

# CORS
CORS_ORIGIN=https://tour-crm.vercel.app,http://localhost:3000

# API
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
```

### Gestión de Secretos

**❌ NUNCA hacer:**
- Commitear archivos `.env` con credenciales reales
- Hardcodear contraseñas en el código
- Exponer tokens en logs

**✅ SIEMPRE hacer:**
- Usar `.env.example` como plantilla
- Configurar variables en plataformas de deploy
- Usar GitHub Secrets para CI/CD
- Rotar credenciales periódicamente

---

## Dominios y URLs

### URLs de Producción

**Frontend:**
- Principal: `https://tour-crm.vercel.app`
- Alternativa: `https://aquatour-crm.vercel.app` (si configurado)

**Backend:**
- API: `https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api`
- Health: `https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api/health`

### URLs de Desarrollo

**Frontend:**
- Local: `http://localhost:PORT` (puerto aleatorio de Flutter)

**Backend:**
- Local: `http://localhost:8080/api`

### Configurar Dominio Personalizado

**En Vercel:**
1. Ir a Settings → Domains
2. Agregar dominio (ej: `crm.aquatour.com`)
3. Configurar DNS según instrucciones
4. Esperar propagación (hasta 48h)

**En Clever Cloud:**
1. Ir a Domain names
2. Agregar dominio personalizado
3. Configurar CNAME en DNS
4. Verificar dominio

---

## Monitoreo y Logs

### Logs de Vercel

**Acceso:**
- Dashboard de Vercel → Deployments → [Deployment] → Logs

**Tipos de logs:**
- Build logs (construcción)
- Function logs (si hay serverless functions)
- Edge logs (requests en CDN)

### Logs de Clever Cloud

**Acceso:**
- Dashboard de Clever Cloud → Logs

**Comandos:**
```bash
# Ver logs en tiempo real
clever logs

# Ver logs de aplicación
clever logs --app app_xxx

# Ver logs de base de datos
clever logs --addon addon_xxx
```

### Monitoreo de Base de Datos

**Métricas disponibles:**
- Conexiones activas
- Queries por segundo
- Uso de almacenamiento
- CPU y RAM

**Acceso:**
- Dashboard de Clever Cloud → MySQL Add-on → Metrics

### Health Checks

**Endpoint de salud:**
```bash
curl https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api/health
```

**Respuesta esperada:**
```json
{
  "status": "ok",
  "timestamp": 1696969696969
}
```

---

## Troubleshooting

### Problemas Comunes

#### 1. Error de Build en Vercel

**Síntoma:** Build falla con error de Flutter

**Solución:**
```bash
# Verificar que build.sh tiene permisos
chmod +x build.sh

# Verificar versión de Flutter en build.sh
# Actualizar URL de descarga si es necesario
```

#### 2. Error de Conexión a Base de Datos

**Síntoma:** `ECONNREFUSED` o `Too many connections`

**Solución:**
```javascript
// Reducir connectionLimit en pool
connectionLimit: 3,  // En lugar de 5 o 10

// Verificar que conexiones se cierran
pool.end();
```

#### 3. CORS Error

**Síntoma:** `Access-Control-Allow-Origin` error

**Solución:**
```javascript
// Verificar CORS_ORIGIN en backend
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true,
}));
```

#### 4. Variables de Entorno No Cargadas

**Síntoma:** `undefined` en variables de entorno

**Solución:**
```bash
# Verificar que están configuradas en plataforma
# Vercel: Settings → Environment Variables
# Clever Cloud: Environment variables

# Reiniciar aplicación después de cambios
```

#### 5. Deploy Lento o Timeout

**Síntoma:** Deploy tarda más de 10 minutos

**Solución:**
```bash
# Limpiar cache de Vercel
vercel --force

# Verificar tamaño de dependencias
# Optimizar build.sh
```

---

## Procedimientos de Despliegue

### Despliegue de Frontend

**Automático (Recomendado):**
```bash
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main
# GitHub Actions despliega automáticamente
```

**Manual:**
```bash
# Instalar Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy a producción
vercel --prod
```

### Despliegue de Backend

**Automático (Git Push):**
```bash
git push clever main
```

**Manual (Desde Dashboard):**
1. Ir a Clever Cloud Dashboard
2. Seleccionar aplicación
3. Ir a Information → Restart
4. Confirmar restart

### Rollback

**En Vercel:**
1. Ir a Deployments
2. Seleccionar deployment anterior
3. Clic en "Promote to Production"

**En Clever Cloud:**
1. Hacer `git revert` del commit problemático
2. Push a clever
3. O usar dashboard para redeploy de commit anterior

### Migración de Base de Datos

**Proceso:**
```bash
# 1. Backup de BD actual
mysqldump -h HOST -u USER -p DB > backup_pre_migration.sql

# 2. Ejecutar script de migración
mysql -h HOST -u USER -p DB < migration.sql

# 3. Verificar cambios
mysql -h HOST -u USER -p DB -e "DESCRIBE tabla_modificada;"

# 4. Backup post-migración
mysqldump -h HOST -u USER -p DB > backup_post_migration.sql
```

---

## Checklist de Despliegue

### Pre-Deploy

- [ ] Tests locales pasan
- [ ] Variables de entorno actualizadas
- [ ] Migraciones de BD preparadas (si aplica)
- [ ] Backup de BD realizado
- [ ] Changelog actualizado
- [ ] Versión incrementada en `pubspec.yaml` y `package.json`

### Durante Deploy

- [ ] Monitorear logs de build
- [ ] Verificar que no hay errores
- [ ] Esperar confirmación de deploy exitoso

### Post-Deploy

- [ ] Verificar health check: `/api/health`
- [ ] Probar login en producción
- [ ] Verificar funcionalidades críticas
- [ ] Revisar logs por errores
- [ ] Notificar al equipo

---

## Costos y Límites

### Vercel (Plan Hobby)

- **Costo:** $0/mes
- **Bandwidth:** 100 GB/mes
- **Build time:** 100 horas/mes
- **Deployments:** Ilimitados
- **Dominios:** Ilimitados

### Clever Cloud (Plan Gratuito)

**Node.js:**
- **Costo:** $0/mes
- **RAM:** Compartida
- **Escalado:** Manual

**MySQL:**
- **Costo:** $0/mes
- **Almacenamiento:** 256 MB
- **Conexiones:** 5 máximo
- **Backups:** 7 días

### Upgrade Paths

**Cuando escalar:**
- Más de 100 GB bandwidth/mes
- Más de 256 MB en BD
- Necesidad de más conexiones MySQL
- Requerimientos de SLA

**Planes recomendados:**
- Vercel Pro: $20/mes
- Clever Cloud Small: €7/mes (Node.js)
- Clever Cloud Small: €7/mes (MySQL)

---

**Fin de la documentación de Despliegue**
