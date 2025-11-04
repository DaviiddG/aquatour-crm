# 🚀 Guía Completa de Despliegue - Aquatour CRM

## 📋 Problema Actual

Tu frontend está desplegado en Vercel, pero el **backend NO está desplegado**, por eso:
- ❌ No aparecen logs de auditoría
- ❌ No aparecen logs de acceso
- ❌ Error: "Failed to fetch" en la consola

## ✅ Solución Rápida (Recomendada)

### Usar Railway para el Backend

Railway es **GRATIS** y perfecto para backends con bases de datos.

---

## 🎯 Paso a Paso - Desplegar Backend en Railway

### 1️⃣ Crear Cuenta en Railway

1. Ve a: https://railway.app
2. Click en **"Start a New Project"**
3. Inicia sesión con tu cuenta de GitHub
4. Autoriza Railway para acceder a tus repositorios

### 2️⃣ Crear Nuevo Proyecto

1. Click en **"New Project"**
2. Selecciona **"Deploy from GitHub repo"**
3. Busca y selecciona: **`aquatour-crm`**
4. Railway detectará automáticamente que es Node.js

### 3️⃣ Configurar el Proyecto

1. En Railway, click en tu proyecto
2. Ve a **"Settings"**
3. En **"Root Directory"**, escribe: `server`
4. En **"Start Command"**, escribe: `npm start`
5. Click en **"Save"**

### 4️⃣ Agregar Variables de Entorno

1. Click en la pestaña **"Variables"**
2. Agrega estas variables (usa tus credenciales de Clever Cloud):

```env
DB_HOST=tu-host.clever-cloud.com
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=aquatour
DB_PORT=3306
PORT=8080
NODE_ENV=production
CORS_ORIGIN=https://aquatour-crm.vercel.app
JWT_SECRET=tu_secreto_jwt_aqui
```

3. Click en **"Add"** para cada variable

### 5️⃣ Desplegar

1. Railway desplegará automáticamente
2. Espera 2-3 minutos
3. Verás el estado: **"Deployed"** ✅

### 6️⃣ Obtener la URL del Backend

1. En Railway, click en tu servicio
2. Ve a **"Settings"**
3. Busca **"Domains"**
4. Click en **"Generate Domain"**
5. Copia la URL (ejemplo: `https://aquatour-backend-production.up.railway.app`)

---

## 🔄 Actualizar el Frontend con la Nueva URL

Ahora necesitas actualizar el frontend para que use la URL del backend de Railway.

### Archivos a Modificar:

#### 1. `lib/services/api_service.dart`

Busca esta línea:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
```

Cámbiala por:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-URL-DE-RAILWAY.up.railway.app/api',
);
```

#### 2. `lib/services/audit_service.dart`

Busca:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
```

Cámbiala por:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-URL-DE-RAILWAY.up.railway.app/api',
);
```

#### 3. `lib/services/access_log_service.dart`

Busca:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
```

Cámbiala por:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-URL-DE-RAILWAY.up.railway.app/api',
);
```

---

## 🚀 Redesplegar el Frontend

### Opción A: Desde la Terminal

```bash
# 1. Hacer commit de los cambios
git add .
git commit -m "Actualizar URL del backend a Railway"
git push origin main

# 2. Vercel redesplegará automáticamente
```

### Opción B: Desde Vercel Dashboard

1. Ve a https://vercel.com
2. Entra a tu proyecto **aquatour-crm**
3. Click en **"Redeploy"**
4. Espera 2-3 minutos

---

## ✅ Verificar que Todo Funciona

### 1. Probar el Backend

Abre en tu navegador:
```
https://TU-URL-DE-RAILWAY.up.railway.app/api/health
```

Deberías ver:
```json
{"status":"ok","timestamp":1234567890}
```

### 2. Probar el Frontend

1. Ve a: https://aquatour-crm.vercel.app
2. Inicia sesión
3. Ve a **"Registro de Accesos"** (como superadmin)
4. ✅ Deberías ver tu acceso registrado
5. Ve a **"Auditoría del Sistema"**
6. ✅ Deberías ver los logs

---

## 🎯 Resumen Visual

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ANTES (No funcionaba):                                 │
│                                                         │
│  Frontend (Vercel) ──X──> Backend (localhost) ❌       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  DESPUÉS (Funciona):                                    │
│                                                         │
│  Frontend (Vercel) ──✓──> Backend (Railway) ✅         │
│                            │                            │
│                            └──> Base de Datos (Clever)  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Solución de Problemas

### Error: "Failed to fetch"
**Causa:** El backend no está corriendo o la URL es incorrecta.

**Solución:**
1. Verifica que Railway muestre "Deployed"
2. Prueba la URL del backend en el navegador
3. Revisa los logs en Railway

### Error: "CORS policy"
**Causa:** El backend no permite requests desde tu frontend.

**Solución:**
1. En Railway, agrega la variable:
   ```
   CORS_ORIGIN=https://aquatour-crm.vercel.app
   ```
2. Redespliega el backend

### Error: "Cannot connect to database"
**Causa:** Las credenciales de Clever Cloud son incorrectas.

**Solución:**
1. Ve a Clever Cloud
2. Copia las credenciales correctas
3. Actualiza las variables en Railway
4. Redespliega

### Los logs no aparecen
**Causa:** La tabla `access_logs` no existe en la base de datos.

**Solución:**
1. Conecta a tu base de datos de Clever Cloud
2. Ejecuta el script: `server/create-access-logs-table.sql`

---

## 📊 Costos

| Servicio | Plan | Costo |
|----------|------|-------|
| **Vercel** (Frontend) | Hobby | 🆓 Gratis |
| **Railway** (Backend) | Starter | 🆓 $5 gratis/mes |
| **Clever Cloud** (BD) | Free | 🆓 Gratis |

**Total: GRATIS** (con límites generosos)

---

## 🎉 ¡Listo!

Una vez completados todos los pasos:
- ✅ Frontend funcionando en Vercel
- ✅ Backend funcionando en Railway
- ✅ Base de datos en Clever Cloud
- ✅ Logs de auditoría funcionando
- ✅ Logs de acceso funcionando

---

## 📞 ¿Necesitas Ayuda?

Si algo no funciona:
1. Revisa los logs en Railway (pestaña "Deployments")
2. Revisa la consola del navegador (F12)
3. Verifica que todas las URLs estén correctas
4. Asegúrate de que las variables de entorno estén bien configuradas

---

## 🚀 Comandos Rápidos

```bash
# Ver logs del backend en Railway
railway logs

# Redesplegar backend
railway up

# Redesplegar frontend
vercel --prod
```
