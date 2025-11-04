# 🚀 Desplegar Backend en Vercel

## Problema Actual
El frontend está desplegado en Vercel, pero el backend (API) no está disponible, por eso los logs de auditoría y acceso no funcionan.

## ✅ Solución: Desplegar Backend Separado

### Opción 1: Vercel (Recomendado para desarrollo)

#### Paso 1: Instalar Vercel CLI
```bash
npm install -g vercel
```

#### Paso 2: Iniciar sesión en Vercel
```bash
vercel login
```

#### Paso 3: Desplegar el backend
```bash
cd server
vercel --prod
```

#### Paso 4: Obtener la URL del backend
Vercel te dará una URL como: `https://aquatour-backend.vercel.app`

#### Paso 5: Actualizar la URL en el frontend
En `lib/services/api_service.dart` y otros servicios, cambiar:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://aquatour-backend.vercel.app/api', // Tu URL de Vercel
);
```

---

### Opción 2: Railway (Recomendado para producción)

Railway es mejor para backends con bases de datos.

#### Paso 1: Crear cuenta en Railway
1. Ve a https://railway.app
2. Inicia sesión con GitHub

#### Paso 2: Crear nuevo proyecto
1. Click en "New Project"
2. Selecciona "Deploy from GitHub repo"
3. Selecciona tu repositorio `aquatour-crm`
4. Railway detectará automáticamente Node.js

#### Paso 3: Configurar variables de entorno
En Railway, agrega estas variables:
```
DB_HOST=tu_host_mysql
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=aquatour
DB_PORT=3306
PORT=8080
NODE_ENV=production
CORS_ORIGIN=https://aquatour-crm.vercel.app
```

#### Paso 4: Obtener la URL
Railway te dará una URL como: `https://aquatour-backend.up.railway.app`

#### Paso 5: Actualizar el frontend
Igual que en Opción 1, actualizar la URL en los servicios.

---

### Opción 3: Render (Alternativa gratuita)

#### Paso 1: Crear cuenta en Render
1. Ve a https://render.com
2. Inicia sesión con GitHub

#### Paso 2: Crear Web Service
1. Click en "New +"
2. Selecciona "Web Service"
3. Conecta tu repositorio
4. Configuración:
   - **Root Directory:** `server`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`

#### Paso 3: Variables de entorno
Agrega las mismas variables que en Railway.

#### Paso 4: Obtener URL
Render te dará una URL como: `https://aquatour-backend.onrender.com`

---

## 🔄 Actualizar Frontend con la Nueva URL

### Archivos a modificar:

1. **`lib/services/api_service.dart`**
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-BACKEND-URL.com/api',
);
```

2. **`lib/services/audit_service.dart`**
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-BACKEND-URL.com/api',
);
```

3. **`lib/services/access_log_service.dart`**
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://TU-BACKEND-URL.com/api',
);
```

### Redesplegar Frontend
```bash
# En la raíz del proyecto
flutter build web
vercel --prod
```

---

## 🎯 Recomendación Final

**Para producción, usa Railway o Render** porque:
- ✅ Mejor para aplicaciones con bases de datos
- ✅ Siempre activo (no se duerme)
- ✅ Más fácil de configurar variables de entorno
- ✅ Mejor para APIs REST

**Vercel es mejor solo para el frontend** (Flutter Web).

---

## 📝 Checklist de Despliegue

- [ ] Backend desplegado en Railway/Render/Vercel
- [ ] Variables de entorno configuradas
- [ ] URL del backend obtenida
- [ ] Frontend actualizado con nueva URL
- [ ] Frontend redesplegado
- [ ] Probar login
- [ ] Probar auditoría
- [ ] Probar registro de accesos

---

## 🆘 Si tienes problemas

### Error: "Failed to fetch"
- Verifica que el backend esté corriendo
- Verifica las variables de entorno
- Revisa los logs del backend

### Error: CORS
Asegúrate de que en `server/src/server.js` esté configurado:
```javascript
app.use(cors({
  origin: 'https://aquatour-crm.vercel.app',
  credentials: true,
}));
```

### Base de datos no conecta
- Verifica que Clever Cloud esté activo
- Verifica las credenciales en las variables de entorno
- Asegúrate de que la IP del servidor esté permitida en Clever Cloud
