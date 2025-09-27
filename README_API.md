# API Backend para Aquatour CRM

Este documento describe la API REST que debe implementar el backend de Python para el sistema Aquatour CRM.

## Tecnologías Recomendadas

- **Framework**: FastAPI (Python)
- **Base de datos**: MySQL con SQLAlchemy
- **Autenticación**: JWT (JSON Web Tokens)
- **Documentación**: Swagger UI (incluido en FastAPI)

## Estructura de la API

### Base URL
```
http://localhost:8000/api/v1
```

### Autenticación
Todas las rutas protegidas requieren un header `Authorization: Bearer <token>`

## Endpoints Requeridos

### 🔐 Autenticación

#### POST `/auth/login`
Login de usuario.

**Request:**
```json
{
  "email": "usuario@aquatour.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "user": {
    "id_usuario": 1,
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "usuario@aquatour.com",
    "rol": "administrador"
  }
}
```

#### POST `/auth/logout`
Logout de usuario (requiere token).

#### GET `/auth/verify`
Verificar token válido.

### 👥 Usuarios

#### GET `/users`
Obtener todos los usuarios (solo admin).

#### GET `/users/{id}`
Obtener usuario por ID.

#### POST `/users`
Crear nuevo usuario.

**Request:**
```json
{
  "nombre": "Juan",
  "apellido": "Pérez",
  "email": "juan@aquatour.com",
  "rol": "empleado",
  "tipoDocumento": "CC",
  "numDocumento": "12345678",
  "fechaNacimiento": "1990-01-01",
  "genero": "Masculino",
  "telefono": "+57 300 123 4567",
  "direccion": "Calle 123",
  "ciudadResidencia": "Bogotá",
  "paisResidencia": "Colombia",
  "contrasena": "password123",
  "activo": true
}
```

#### PUT `/users/{id}`
Actualizar usuario.

#### DELETE `/users/{id}`
Eliminar usuario.

#### GET `/users/check-email/{email}`
Verificar si email existe.

### 📞 Contactos

#### GET `/contacts`
Obtener todos los contactos.

#### GET `/contacts/{id}`
Obtener contacto por ID.

#### POST `/contacts`
Crear nuevo contacto.

**Request:**
```json
{
  "name": "Empresa ABC",
  "email": "contacto@empresa.com",
  "phone": "+57 301 234 5678",
  "company": "Empresa ABC",
  "notes": "Notas adicionales"
}
```

#### PUT `/contacts/{id}`
Actualizar contacto.

#### DELETE `/contacts/{id}`
Eliminar contacto.

### 📊 Dashboard

#### GET `/dashboard/stats`
Obtener estadísticas del dashboard.

**Response:**
```json
{
  "total_users": 25,
  "total_contacts": 150,
  "active_users": 22,
  "recent_contacts": 5
}
```

## Modelos de Base de Datos

### Usuario
```sql
CREATE TABLE usuarios (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  rol ENUM('empleado', 'administrador', 'superadministrador') NOT NULL,
  tipoDocumento VARCHAR(10),
  numDocumento VARCHAR(50),
  fechaNacimiento DATE,
  genero VARCHAR(20),
  telefono VARCHAR(50),
  direccion TEXT,
  ciudadResidencia VARCHAR(100),
  paisResidencia VARCHAR(100),
  contrasena VARCHAR(255) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Contacto
```sql
CREATE TABLE contactos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Configuración Inicial

### Usuarios por Defecto
Al inicializar la base de datos, crear estos usuarios:

1. **Super Admin**
   - Email: `superadmin@aquatour.com`
   - Password: `superadmin123`
   - Rol: `superadministrador`

2. **Admin**
   - Email: `davidg@aquatour.com`
   - Password: `Osquitar07`
   - Rol: `administrador`

3. **Empleado 1**
   - Email: `empleado@aquatour.com`
   - Password: `empleado123`
   - Rol: `empleado`

4. **Empleado 2**
   - Email: `carmen.vasquez@aquatour.com`
   - Password: `carmen123`
   - Rol: `empleado`

## Seguridad

- Usar bcrypt para hashear contraseñas
- Implementar CORS correctamente
- Validar inputs en el servidor
- Manejar errores apropiadamente
- Logs de auditoría para acciones sensibles

## Despliegue

### Desarrollo Local
```bash
# Instalar dependencias
pip install fastapi uvicorn sqlalchemy pymysql python-jose[cryptography] passlib[bcrypt] python-multipart

# Ejecutar servidor
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Producción
- Usar Gunicorn + Uvicorn workers
- Configurar variables de entorno
- SSL/HTTPS obligatorio
- Rate limiting
- Backup automático de BD

## Testing

### Con Flutter
1. Asegúrate de que la API esté corriendo en `localhost:8000`
2. El archivo `.env` debe tener: `API_BASE_URL=http://localhost:8000/api/v1`
3. La app debería conectarse automáticamente a la API

### Endpoints de Testing
- `GET /docs` - Documentación Swagger
- `GET /redoc` - Documentación alternativa
- `GET /openapi.json` - Esquema OpenAPI

---

**Nota**: Esta API está diseñada para ser implementada con FastAPI, pero puede adaptarse a otros frameworks de Python como Flask o Django REST Framework.
