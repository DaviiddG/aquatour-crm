# Documentación Técnica - Backend Node.js

**Proyecto:** Aquatour CRM  
**Versión:** 1.0.0  
**Última actualización:** Octubre 2025  
**Tecnología:** Node.js + Express + MySQL

---

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Estructura de Directorios](#estructura-de-directorios)
3. [Configuración y Variables de Entorno](#configuración-y-variables-de-entorno)
4. [Base de Datos](#base-de-datos)
5. [Rutas (Routes)](#rutas-routes)
6. [Controladores (Controllers)](#controladores-controllers)
7. [Servicios (Services)](#servicios-services)
8. [Utilidades](#utilidades)
9. [Seguridad](#seguridad)
10. [Despliegue](#despliegue)

---

## Arquitectura General

### Stack Tecnológico
- **Runtime:** Node.js 18+
- **Framework:** Express 4.19
- **Base de Datos:** MySQL 8.0 (Clever Cloud)
- **ORM:** mysql2 (queries directos)
- **Autenticación:** bcryptjs (preparado para JWT)
- **CORS:** cors middleware

### Patrón de Arquitectura
El backend sigue una arquitectura en 3 capas:

```
Routes (Rutas)
    ↓
Controllers (Lógica de negocio y validación)
    ↓
Services (Acceso a datos y operaciones DB)
    ↓
Database (MySQL)
```

### Principios de Diseño
- **Separación de responsabilidades:** Cada capa tiene un propósito específico
- **Reutilización:** Servicios compartidos entre controladores
- **Manejo centralizado de errores:** Middleware global
- **Validación en capas:** Controladores validan entrada, servicios validan negocio

---

## Estructura de Directorios

```
server/
├── src/
│   ├── config/
│   │   └── db.js                      # Configuración de MySQL pool
│   ├── controllers/
│   │   ├── auth.controller.js         # Login
│   │   ├── users.controller.js        # CRUD usuarios
│   │   ├── clients.controller.js      # CRUD clientes
│   │   ├── contacts.controller.js     # CRUD contactos
│   │   ├── destinations.controller.js # CRUD destinos
│   │   ├── packages.controller.js     # CRUD paquetes
│   │   ├── quotes.controller.js       # CRUD cotizaciones
│   │   ├── reservations.controller.js # CRUD reservas
│   │   ├── payments.controller.js     # CRUD pagos
│   │   └── providers.controller.js    # CRUD proveedores
│   ├── routes/
│   │   ├── auth.routes.js             # Rutas de autenticación
│   │   ├── users.routes.js            # Rutas de usuarios
│   │   ├── clients.routes.js          # Rutas de clientes
│   │   ├── contacts.routes.js         # Rutas de contactos
│   │   ├── destinations.routes.js     # Rutas de destinos
│   │   ├── packages.routes.js         # Rutas de paquetes
│   │   ├── quotes.routes.js           # Rutas de cotizaciones
│   │   ├── reservations.routes.js     # Rutas de reservas
│   │   ├── payments.routes.js         # Rutas de pagos
│   │   └── providers.routes.js        # Rutas de proveedores
│   ├── services/
│   │   ├── users.service.js           # Lógica de usuarios
│   │   ├── password.service.js        # Hash y verificación
│   │   ├── clients.service.js         # Lógica de clientes
│   │   ├── contacts.service.js        # Lógica de contactos
│   │   ├── destinations.service.js    # Lógica de destinos
│   │   ├── packages.service.js        # Lógica de paquetes
│   │   ├── quotes.service.js          # Lógica de cotizaciones
│   │   ├── reservations.service.js    # Lógica de reservas
│   │   ├── payments.service.js        # Lógica de pagos
│   │   └── providers.service.js       # Lógica de proveedores
│   ├── utils/
│   │   └── error-handler.js           # Middleware de errores
│   └── server.js                      # Punto de entrada
├── node_modules/
├── package.json
├── .env                               # Variables de entorno (no en git)
├── .gitignore
├── kill-connections.js                # Script para cerrar conexiones MySQL
├── test-db.js                         # Script de prueba de conexión
└── nodemon.json                       # Configuración de nodemon
```

---

## Configuración y Variables de Entorno

### Variables Requeridas

**Archivo `.env`:**
```bash
# Base de datos MySQL (Clever Cloud)
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

# API Base URL (para referencias)
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
```

### Configuración de Base de Datos

**Archivo:** `src/config/db.js`

```javascript
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 3,        // Reducido para plan gratuito
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  idleTimeout: 60000,        // 60 segundos
  maxIdle: 2,
});

export const getConnection = () => pool.getConnection();
export const query = (sql, params) => pool.query(sql, params);
```

**Características:**
- Pool de conexiones con límite de 3 (plan gratuito Clever Cloud)
- Keep-alive para mantener conexiones activas
- Timeout de 60 segundos para conexiones inactivas
- Promesas nativas con `mysql2/promise`

---

## Rutas (Routes)

### Estructura de Rutas

**Servidor principal:** `src/server.js`

```javascript
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/destinations', destinationRoutes);
app.use('/api/reservations', reservationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/api/providers', providerRoutes);
```

### Rutas de Autenticación

**Archivo:** `src/routes/auth.routes.js`

```javascript
POST /api/auth/login
```

**Ejemplo de uso:**
```bash
curl -X POST https://api.aquatour.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@aquatour.com","password":"admin123"}'
```

**Respuesta exitosa:**
```json
{
  "ok": true,
  "user": {
    "id_usuario": 1,
    "nombre": "Admin",
    "apellido": "Aquatour",
    "email": "admin@aquatour.com",
    "rol": "administrador",
    "activo": true
  }
}
```

### Rutas de Usuarios

**Archivo:** `src/routes/users.routes.js`

```javascript
GET    /api/users              // Listar todos los usuarios
GET    /api/users/:idUsuario   // Obtener usuario por ID
POST   /api/users              // Crear nuevo usuario
PUT    /api/users/:idUsuario   // Actualizar usuario
DELETE /api/users/:idUsuario   // Eliminar usuario
GET    /api/users/check-email/:email  // Verificar si email existe
```

### Rutas de Clientes

**Archivo:** `src/routes/clients.routes.js`

```javascript
GET    /api/clients            // Listar todos los clientes
GET    /api/clients/user/:idUsuario  // Clientes de un usuario
GET    /api/clients/:idCliente // Obtener cliente por ID
POST   /api/clients            // Crear nuevo cliente
PUT    /api/clients/:idCliente // Actualizar cliente
DELETE /api/clients/:idCliente // Eliminar cliente
```

### Rutas de Destinos

**Archivo:** `src/routes/destinations.routes.js`

```javascript
GET    /api/destinations           // Listar destinos
GET    /api/destinations/active    // Solo destinos activos
GET    /api/destinations/:idDestino // Obtener destino
POST   /api/destinations           // Crear destino
PUT    /api/destinations/:idDestino // Actualizar destino
DELETE /api/destinations/:idDestino // Eliminar destino
```

### Rutas de Paquetes Turísticos

**Archivo:** `src/routes/packages.routes.js`

```javascript
GET    /api/packages            // Listar paquetes
GET    /api/packages/:idPaquete // Obtener paquete
POST   /api/packages            // Crear paquete
PUT    /api/packages/:idPaquete // Actualizar paquete
DELETE /api/packages/:idPaquete // Eliminar paquete
```

### Rutas de Cotizaciones

**Archivo:** `src/routes/quotes.routes.js`

```javascript
GET    /api/quotes              // Listar cotizaciones
GET    /api/quotes/:idCotizacion // Obtener cotización
POST   /api/quotes              // Crear cotización
PUT    /api/quotes/:idCotizacion // Actualizar cotización
DELETE /api/quotes/:idCotizacion // Eliminar cotización
```

### Rutas de Reservas

**Archivo:** `src/routes/reservations.routes.js`

```javascript
GET    /api/reservations            // Listar reservas
GET    /api/reservations/client/:idCliente // Reservas de cliente
GET    /api/reservations/:idReserva // Obtener reserva
POST   /api/reservations            // Crear reserva
PUT    /api/reservations/:idReserva // Actualizar reserva
DELETE /api/reservations/:idReserva // Eliminar reserva
```

### Rutas de Pagos

**Archivo:** `src/routes/payments.routes.js`

```javascript
GET    /api/payments                    // Listar pagos
GET    /api/payments/reservation/:idReserva // Pagos de reserva
GET    /api/payments/:idPago            // Obtener pago
POST   /api/payments                    // Crear pago
PUT    /api/payments/:idPago            // Actualizar pago
DELETE /api/payments/:idPago            // Eliminar pago
```

### Rutas de Proveedores

**Archivo:** `src/routes/providers.routes.js`

```javascript
GET    /api/providers             // Listar proveedores
GET    /api/providers/:idProveedor // Obtener proveedor
POST   /api/providers             // Crear proveedor
PUT    /api/providers/:idProveedor // Actualizar proveedor
DELETE /api/providers/:idProveedor // Eliminar proveedor
```

### Rutas de Contactos

**Archivo:** `src/routes/contacts.routes.js`

```javascript
GET    /api/contacts             // Listar contactos
GET    /api/contacts/:idContacto // Obtener contacto
POST   /api/contacts             // Crear contacto
PUT    /api/contacts/:idContacto // Actualizar contacto
DELETE /api/contacts/:idContacto // Eliminar contacto
```

---

## Controladores (Controllers)

### AuthController

**Archivo:** `src/controllers/auth.controller.js`

**Función:** `login(req, res, next)`

```javascript
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validación de campos
    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        error: 'Email y contraseña son obligatorios',
      });
    }

    // Buscar usuario por email
    const userRecord = await findByEmail(email);

    if (!userRecord) {
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    // Verificar si está activo
    if (!userRecord.activo) {
      return res.status(403).json({
        ok: false,
        error: 'Usuario inactivo',
      });
    }

    // Verificar contraseña
    const isValidPassword = await verifyPassword(
      password, 
      userRecord.contrasena
    );

    if (!isValidPassword) {
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    // Remover contraseña de la respuesta
    const { contrasena, ...user } = userRecord;

    res.json({
      ok: true,
      user,
    });
  } catch (error) {
    next(error);
  }
};
```

### UsersController

**Archivo:** `src/controllers/users.controller.js`

**Funciones principales:**
- `getAllUsers()` - Lista todos los usuarios
- `getUserById()` - Obtiene un usuario específico
- `createUser()` - Crea nuevo usuario
- `updateUser()` - Actualiza usuario existente
- `deleteUser()` - Elimina usuario
- `checkEmail()` - Verifica disponibilidad de email

**Ejemplo - Crear Usuario:**
```javascript
export const createUser = async (req, res, next) => {
  try {
    const userData = req.body;

    // Verificar email duplicado
    const existingUser = await findByEmail(userData.email);
    if (existingUser) {
      return res.status(409).json({
        ok: false,
        error: 'El email ya está registrado',
      });
    }

    // Crear usuario
    const newUser = await createUserService(userData);

    res.status(201).json({
      ok: true,
      data: newUser,
    });
  } catch (error) {
    next(error);
  }
};
```

### ClientsController

**Archivo:** `src/controllers/clients.controller.js`

Gestiona operaciones CRUD de clientes con validaciones específicas.

### Otros Controladores

Todos los controladores siguen el mismo patrón:
1. Validar entrada
2. Llamar al servicio correspondiente
3. Manejar respuesta o error
4. Usar códigos HTTP apropiados

---

## Servicios (Services)

### UsersService

**Archivo:** `src/services/users.service.js`

**Funciones principales:**

```javascript
// Buscar usuario por email
export const findByEmail = async (email, excludeId)

// Buscar usuario por ID
export const findById = async (idUsuario)

// Listar todos los usuarios
export const findAllUsers = async ()

// Crear nuevo usuario
export const createUser = async (userData)

// Actualizar usuario
export const updateUser = async (idUsuario, userData)

// Eliminar usuario
export const deleteUser = async (idUsuario)
```

**Mapeo de Roles:**
```javascript
const roleDbToApp = {
  Superadministrador: 'superadministrador',
  Administrador: 'administrador',
  Asesor: 'empleado',
  Cliente: 'empleado',
};

const roleAppToDb = {
  superadministrador: 'Superadministrador',
  administrador: 'Administrador',
  empleado: 'Asesor',
};
```

**Mapeo de Documentos:**
```javascript
const docDbToApp = {
  'Cedula Ciudadania': 'CC',
  'Tarjeta Identidad': 'TI',
  'Pasaporte': 'PP',
  'Documento Extranjeria': 'CE',
  'NIT': 'NIT',
};
```

**Mapeo de Género:**
```javascript
const genderDbToApp = {
  M: 'Masculino',
  F: 'Femenino',
  Otro: 'Otro',
};
```

### PasswordService

**Archivo:** `src/services/password.service.js`

```javascript
import bcrypt from 'bcryptjs';

// Hash de contraseña
export const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

// Verificar contraseña
export const verifyPassword = async (password, hash) => {
  // Soporte para contraseñas en texto plano (legacy)
  if (!hash.startsWith('$2a$') && !hash.startsWith('$2b$')) {
    return password === hash;
  }
  return bcrypt.compare(password, hash);
};
```

### ClientsService

**Archivo:** `src/services/clients.service.js`

Operaciones CRUD para clientes con validaciones de negocio.

### Otros Servicios

Cada servicio encapsula la lógica de acceso a datos para su entidad correspondiente:
- `destinations.service.js`
- `packages.service.js`
- `quotes.service.js`
- `reservations.service.js`
- `payments.service.js`
- `providers.service.js`
- `contacts.service.js`

---

## Utilidades

### Error Handler

**Archivo:** `src/utils/error-handler.js`

```javascript
export const errorHandler = (err, req, res, next) => {
  console.error('❌ API Error:', err);

  const status = err.status || 500;
  const message = err.message || 'Error interno del servidor';

  res.status(status).json({
    ok: false,
    error: message,
  });
};
```

**Uso en server.js:**
```javascript
app.use(errorHandler);  // Debe ser el último middleware
```

---

## Seguridad

### CORS

```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true,
}));
```

### Validación de Entrada

- Validación en controladores antes de procesar
- Sanitización de parámetros SQL con prepared statements
- Prevención de SQL injection usando `mysql2` con parámetros

### Contraseñas

- Hash con bcrypt (10 rounds)
- Nunca se devuelven en respuestas API
- Soporte legacy para texto plano (migración gradual)

### Próximas Mejoras de Seguridad

- [ ] Implementar JWT para autenticación stateless
- [ ] Middleware de autorización por roles
- [ ] Rate limiting
- [ ] Helmet.js para headers de seguridad
- [ ] Validación con express-validator
- [ ] Logs de auditoría

---

## Despliegue

### Clever Cloud

**Plataforma:** Clever Cloud  
**URL:** `https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io`

**Configuración:**
- Runtime: Node.js 18
- Build command: `npm install`
- Start command: `npm start`
- Variables de entorno configuradas en panel de Clever Cloud

### Scripts de NPM

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "kill-connections": "node kill-connections.js"
  }
}
```

### Health Check

```javascript
GET /api/health

Response:
{
  "status": "ok",
  "timestamp": 1696969696969
}
```

---

## Dependencias

```json
{
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "mysql2": "^3.9.7"
  },
  "devDependencies": {
    "nodemon": "^3.1.7"
  }
}
```

---

## Testing

### Script de Prueba de Conexión

**Archivo:** `test-db.js`

```javascript
import { query } from './src/config/db.js';

const testConnection = async () => {
  try {
    const [rows] = await query('SELECT 1 + 1 AS result');
    console.log('✅ Conexión exitosa:', rows);
  } catch (error) {
    console.error('❌ Error de conexión:', error);
  }
  process.exit(0);
};

testConnection();
```

**Ejecutar:**
```bash
node test-db.js
```

---

## Próximas Mejoras

1. **Autenticación JWT**
2. **Middleware de autorización**
3. **Tests unitarios con Jest**
4. **Tests de integración con Supertest**
5. **Documentación con Swagger/OpenAPI**
6. **Logs estructurados con Winston**
7. **Monitoreo con Sentry**
8. **Cache con Redis**
9. **Paginación en listados**
10. **Búsqueda y filtros avanzados**

---

**Fin de la documentación del Backend**
