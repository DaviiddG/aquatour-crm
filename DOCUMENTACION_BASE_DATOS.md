# Documentación Técnica - Base de Datos

**Proyecto:** Aquatour CRM  
**Versión:** 1.0.0  
**Última actualización:** Octubre 2025  
**Motor:** MySQL 8.0 (Clever Cloud)

---

## Tabla de Contenidos

1. [Información General](#información-general)
2. [Diagrama de Relaciones](#diagrama-de-relaciones)
3. [Tablas del Sistema](#tablas-del-sistema)
4. [Relaciones entre Tablas](#relaciones-entre-tablas)
5. [Índices y Optimizaciones](#índices-y-optimizaciones)
6. [Migraciones](#migraciones)
7. [Datos de Prueba](#datos-de-prueba)
8. [Backup y Restauración](#backup-y-restauración)

---

## Información General

### Configuración de Conexión

**Proveedor:** Clever Cloud  
**Plan:** Gratuito (máx. 5 conexiones simultáneas)  
**Región:** EU (Europa)  
**Charset:** utf8mb4  
**Collation:** utf8mb4_unicode_ci

**Parámetros de Conexión:**
```
Host: bxxx-mysql.services.clever-cloud.com
Port: 3306
Database: bxxx
User: uxxx
Password: [configurado en variables de entorno]
```

### Límites del Plan Gratuito

- **Conexiones simultáneas:** 5 máximo
- **Almacenamiento:** 256 MB
- **Conexiones configuradas en pool:** 3 (para dejar margen)
- **Timeout de conexión:** 60 segundos

---

## Diagrama de Relaciones

```
┌─────────────┐
│     Rol     │
└──────┬──────┘
       │
       │ 1:N
       │
┌──────▼──────┐         ┌──────────────┐
│   Usuario   │────────▶│   Cliente    │
└──────┬──────┘  1:N    └──────┬───────┘
       │                        │
       │ 1:N                    │ 1:N
       │                        │
┌──────▼──────┐         ┌──────▼───────┐
│ Cotizacion  │────────▶│   Reserva    │
└──────┬──────┘  1:1    └──────┬───────┘
       │                        │
       │                        │ 1:N
       │                        │
       │                 ┌──────▼───────┐
       │                 │     Pago     │
       │                 └──────────────┘
       │
       │ N:1
       │
┌──────▼──────────┐
│ Paquete_Turismo │
└──────┬──────────┘
       │
       │ N:N (via destinos_ids)
       │
┌──────▼──────┐
│   Destino   │
└─────────────┘

┌──────────────┐
│  Proveedor   │
└──────────────┘

┌──────────────┐
│   Contacto   │
└──────────────┘
```

---

## Tablas del Sistema

### 1. Rol

Catálogo de roles del sistema.

```sql
CREATE TABLE Rol (
  id_rol INT PRIMARY KEY AUTO_INCREMENT,
  rol VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id_rol`: Identificador único
- `rol`: Nombre del rol (Superadministrador, Administrador, Asesor, Cliente)
- `descripcion`: Descripción del rol
- `fecha_registro`: Fecha de creación

**Datos iniciales:**
```sql
INSERT INTO Rol (rol, descripcion) VALUES
('Superadministrador', 'Control total del sistema'),
('Administrador', 'Gestión completa del CRM'),
('Asesor', 'Empleado con acceso limitado'),
('Cliente', 'Cliente externo');
```

---

### 2. Usuario

Usuarios del sistema (empleados y administradores).

```sql
CREATE TABLE Usuario (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  correo VARCHAR(150) NOT NULL UNIQUE,
  contrasena VARCHAR(255) NOT NULL,
  id_rol INT,
  tipo_documento ENUM('Cedula Ciudadania', 'Tarjeta Identidad', 'Pasaporte', 
                      'Documento Extranjeria', 'NIT'),
  num_documento VARCHAR(50),
  fecha_nacimiento DATE,
  genero ENUM('M', 'F', 'Otro'),
  telefono VARCHAR(20),
  direccion VARCHAR(255),
  ciudad_residencia VARCHAR(100),
  pais_residencia VARCHAR(100),
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_rol) REFERENCES Rol(id_rol)
);
```

**Campos principales:**
- `id_usuario`: Identificador único
- `nombre`, `apellido`: Nombre completo
- `correo`: Email único para login
- `contrasena`: Hash bcrypt de la contraseña
- `id_rol`: Referencia a tabla Rol
- `tipo_documento`: Tipo de documento de identidad
- `num_documento`: Número de documento
- `fecha_nacimiento`: Fecha de nacimiento
- `genero`: M (Masculino), F (Femenino), Otro
- `telefono`: Teléfono de contacto
- `direccion`: Dirección completa
- `ciudad_residencia`, `pais_residencia`: Ubicación
- `fecha_registro`: Timestamp de creación

**Índices:**
```sql
CREATE INDEX idx_usuario_correo ON Usuario(correo);
CREATE INDEX idx_usuario_rol ON Usuario(id_rol);
```

---

### 3. Cliente

Clientes potenciales y confirmados.

```sql
CREATE TABLE Cliente (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  correo VARCHAR(150),
  telefono VARCHAR(20),
  nacionalidad VARCHAR(100),
  tipo_documento ENUM('CC', 'TI', 'PP', 'CE', 'NIT'),
  num_documento VARCHAR(50),
  fecha_nacimiento DATE,
  genero ENUM('Masculino', 'Femenino', 'Otro'),
  direccion VARCHAR(255),
  ciudad VARCHAR(100),
  pais VARCHAR(100),
  fuente_contacto VARCHAR(100),
  nivel_interes ENUM('Alto', 'Medio', 'Bajo'),
  observaciones TEXT,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);
```

**Campos principales:**
- `id_cliente`: Identificador único
- `id_usuario`: Usuario (asesor) que captó al cliente
- `nombre`, `apellido`: Nombre completo
- `correo`, `telefono`: Contacto
- `nacionalidad`: País de origen
- `tipo_documento`: CC, TI, PP, CE, NIT
- `num_documento`: Número de documento
- `fecha_nacimiento`: Fecha de nacimiento
- `genero`: Masculino, Femenino, Otro
- `direccion`, `ciudad`, `pais`: Ubicación
- `fuente_contacto`: Cómo llegó el cliente (Redes sociales, Referido, etc.)
- `nivel_interes`: Alto, Medio, Bajo
- `observaciones`: Notas adicionales
- `fecha_registro`: Fecha de creación
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_cliente_usuario ON Cliente(id_usuario);
CREATE INDEX idx_cliente_correo ON Cliente(correo);
CREATE INDEX idx_cliente_nivel_interes ON Cliente(nivel_interes);
```

---

### 4. Destino

Destinos turísticos disponibles.

```sql
CREATE TABLE Destino (
  id_destino INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(150) NOT NULL,
  pais VARCHAR(100) NOT NULL,
  ciudad VARCHAR(100),
  descripcion TEXT,
  imagen_url VARCHAR(500),
  activo BOOLEAN DEFAULT TRUE,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Campos principales:**
- `id_destino`: Identificador único
- `nombre`: Nombre del destino
- `pais`: País
- `ciudad`: Ciudad específica
- `descripcion`: Descripción detallada
- `imagen_url`: URL de imagen del destino
- `activo`: Si está disponible para venta
- `fecha_registro`: Fecha de creación
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_destino_pais ON Destino(pais);
CREATE INDEX idx_destino_activo ON Destino(activo);
```

---

### 5. Paquete_Turismo

Paquetes turísticos ofrecidos.

```sql
CREATE TABLE Paquete_Turismo (
  id_paquete INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT,
  duracion_dias INT NOT NULL,
  precio_base DECIMAL(10, 2) NOT NULL,
  destinos_ids VARCHAR(255),
  itinerario TEXT,
  incluye TEXT,
  no_incluye TEXT,
  activo BOOLEAN DEFAULT TRUE,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Campos principales:**
- `id_paquete`: Identificador único
- `nombre`: Nombre del paquete
- `descripcion`: Descripción general
- `duracion_dias`: Duración en días
- `precio_base`: Precio base en USD o COP
- `destinos_ids`: IDs de destinos separados por comas (ej: "1,3,5")
- `itinerario`: Itinerario detallado día a día
- `incluye`: Qué incluye el paquete
- `no_incluye`: Qué NO incluye
- `activo`: Si está disponible para venta
- `fecha_registro`: Fecha de creación
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_paquete_activo ON Paquete_Turismo(activo);
CREATE INDEX idx_paquete_precio ON Paquete_Turismo(precio_base);
```

**Nota:** La columna `destinos_ids` permite múltiples destinos por paquete.

---

### 6. Cotizacion

Cotizaciones generadas para clientes.

```sql
CREATE TABLE Cotizacion (
  id_cotizacion INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT NOT NULL,
  id_usuario INT NOT NULL,
  id_paquete INT,
  fecha_cotizacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_viaje DATE,
  num_personas INT NOT NULL,
  precio_total DECIMAL(10, 2) NOT NULL,
  estado ENUM('Pendiente', 'Enviada', 'Aceptada', 'Rechazada', 'Expirada') 
         DEFAULT 'Pendiente',
  observaciones TEXT,
  fecha_expiracion DATE,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
  FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario),
  FOREIGN KEY (id_paquete) REFERENCES Paquete_Turismo(id_paquete)
);
```

**Campos principales:**
- `id_cotizacion`: Identificador único
- `id_cliente`: Cliente que solicita
- `id_usuario`: Asesor que genera la cotización
- `id_paquete`: Paquete cotizado (opcional)
- `fecha_cotizacion`: Fecha de creación
- `fecha_viaje`: Fecha estimada del viaje
- `num_personas`: Número de personas
- `precio_total`: Precio total cotizado
- `estado`: Pendiente, Enviada, Aceptada, Rechazada, Expirada
- `observaciones`: Notas adicionales
- `fecha_expiracion`: Fecha límite de validez
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_cotizacion_cliente ON Cotizacion(id_cliente);
CREATE INDEX idx_cotizacion_usuario ON Cotizacion(id_usuario);
CREATE INDEX idx_cotizacion_estado ON Cotizacion(estado);
CREATE INDEX idx_cotizacion_fecha ON Cotizacion(fecha_cotizacion);
```

---

### 7. Reserva

Reservas confirmadas.

```sql
CREATE TABLE Reserva (
  id_reserva INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT NOT NULL,
  id_cotizacion INT,
  id_usuario INT NOT NULL,
  fecha_reserva DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  num_personas INT NOT NULL,
  monto_total DECIMAL(10, 2) NOT NULL,
  monto_pagado DECIMAL(10, 2) DEFAULT 0,
  estado ENUM('Pendiente', 'Confirmada', 'Pagada', 'Cancelada', 'Completada') 
         DEFAULT 'Pendiente',
  observaciones TEXT,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
  FOREIGN KEY (id_cotizacion) REFERENCES Cotizacion(id_cotizacion),
  FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);
```

**Campos principales:**
- `id_reserva`: Identificador único
- `id_cliente`: Cliente que reserva
- `id_cotizacion`: Cotización origen (opcional)
- `id_usuario`: Asesor responsable
- `fecha_reserva`: Fecha de creación
- `fecha_inicio`: Inicio del viaje
- `fecha_fin`: Fin del viaje
- `num_personas`: Número de personas
- `monto_total`: Monto total a pagar
- `monto_pagado`: Monto ya pagado
- `estado`: Pendiente, Confirmada, Pagada, Cancelada, Completada
- `observaciones`: Notas adicionales
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_reserva_cliente ON Reserva(id_cliente);
CREATE INDEX idx_reserva_usuario ON Reserva(id_usuario);
CREATE INDEX idx_reserva_estado ON Reserva(estado);
CREATE INDEX idx_reserva_fecha_inicio ON Reserva(fecha_inicio);
```

---

### 8. Pago

Pagos realizados por reservas.

```sql
CREATE TABLE Pago (
  id_pago INT PRIMARY KEY AUTO_INCREMENT,
  id_reserva INT NOT NULL,
  monto DECIMAL(10, 2) NOT NULL,
  fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
  metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia', 'PayPal', 'Otro') 
              NOT NULL,
  referencia VARCHAR(100),
  observaciones TEXT,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_reserva) REFERENCES Reserva(id_reserva)
);
```

**Campos principales:**
- `id_pago`: Identificador único
- `id_reserva`: Reserva asociada
- `monto`: Monto del pago
- `fecha_pago`: Fecha del pago
- `metodo_pago`: Efectivo, Tarjeta, Transferencia, PayPal, Otro
- `referencia`: Número de referencia/transacción
- `observaciones`: Notas adicionales
- `fecha_registro`: Timestamp de creación

**Índices:**
```sql
CREATE INDEX idx_pago_reserva ON Pago(id_reserva);
CREATE INDEX idx_pago_fecha ON Pago(fecha_pago);
CREATE INDEX idx_pago_metodo ON Pago(metodo_pago);
```

---

### 9. Proveedor

Proveedores de servicios turísticos.

```sql
CREATE TABLE Proveedor (
  id_proveedor INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(200) NOT NULL,
  tipo_servicio VARCHAR(100),
  pais VARCHAR(100),
  ciudad VARCHAR(100),
  telefono VARCHAR(20),
  correo VARCHAR(150),
  contacto_principal VARCHAR(200),
  observaciones TEXT,
  activo BOOLEAN DEFAULT TRUE,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Campos principales:**
- `id_proveedor`: Identificador único
- `nombre`: Nombre del proveedor
- `tipo_servicio`: Tipo de servicio (Hotel, Transporte, Guía, etc.)
- `pais`, `ciudad`: Ubicación
- `telefono`, `correo`: Contacto
- `contacto_principal`: Persona de contacto
- `observaciones`: Notas adicionales
- `activo`: Si está activo
- `fecha_registro`: Fecha de creación
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_proveedor_tipo ON Proveedor(tipo_servicio);
CREATE INDEX idx_proveedor_activo ON Proveedor(activo);
```

---

### 10. Contacto

Contactos generales (no necesariamente clientes).

```sql
CREATE TABLE Contacto (
  id_contacto INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100),
  empresa VARCHAR(200),
  cargo VARCHAR(100),
  telefono VARCHAR(20),
  correo VARCHAR(150),
  pais VARCHAR(100),
  ciudad VARCHAR(100),
  observaciones TEXT,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Campos principales:**
- `id_contacto`: Identificador único
- `nombre`, `apellido`: Nombre completo
- `empresa`: Empresa donde trabaja
- `cargo`: Cargo/posición
- `telefono`, `correo`: Contacto
- `pais`, `ciudad`: Ubicación
- `observaciones`: Notas adicionales
- `fecha_registro`: Fecha de creación
- `fecha_actualizacion`: Última actualización

**Índices:**
```sql
CREATE INDEX idx_contacto_correo ON Contacto(correo);
CREATE INDEX idx_contacto_empresa ON Contacto(empresa);
```

---

## Relaciones entre Tablas

### Relaciones Principales

1. **Rol → Usuario (1:N)**
   - Un rol puede tener múltiples usuarios
   - Un usuario tiene un solo rol

2. **Usuario → Cliente (1:N)**
   - Un usuario (asesor) puede tener múltiples clientes
   - Un cliente pertenece a un usuario

3. **Cliente → Cotizacion (1:N)**
   - Un cliente puede tener múltiples cotizaciones
   - Una cotización pertenece a un cliente

4. **Usuario → Cotizacion (1:N)**
   - Un usuario puede generar múltiples cotizaciones
   - Una cotización es generada por un usuario

5. **Paquete_Turismo → Cotizacion (1:N)**
   - Un paquete puede estar en múltiples cotizaciones
   - Una cotización puede referenciar un paquete (opcional)

6. **Cotizacion → Reserva (1:1 o 1:0)**
   - Una cotización puede convertirse en una reserva
   - Una reserva puede originarse de una cotización (opcional)

7. **Cliente → Reserva (1:N)**
   - Un cliente puede tener múltiples reservas
   - Una reserva pertenece a un cliente

8. **Reserva → Pago (1:N)**
   - Una reserva puede tener múltiples pagos
   - Un pago pertenece a una reserva

9. **Paquete_Turismo ↔ Destino (N:N via destinos_ids)**
   - Un paquete puede incluir múltiples destinos
   - Un destino puede estar en múltiples paquetes

---

## Índices y Optimizaciones

### Índices Implementados

**Índices de búsqueda frecuente:**
- `idx_usuario_correo` - Login de usuarios
- `idx_cliente_usuario` - Clientes por asesor
- `idx_cotizacion_estado` - Filtrado por estado
- `idx_reserva_fecha_inicio` - Búsqueda por fechas
- `idx_pago_reserva` - Pagos de una reserva

**Índices de claves foráneas:**
- Todas las FK tienen índices automáticos para joins eficientes

### Optimizaciones Aplicadas

1. **Connection Pooling:** Pool de 3 conexiones para evitar límite
2. **Índices selectivos:** Solo en columnas de búsqueda frecuente
3. **DATETIME vs TIMESTAMP:** Uso de DATETIME para evitar problemas de zona horaria
4. **ON UPDATE CURRENT_TIMESTAMP:** Actualización automática de fecha_actualizacion
5. **ENUM para estados:** Validación a nivel de BD

---

## Migraciones

### Migración: Múltiples Destinos por Paquete

**Archivo:** `server/migrations/add_destinos_ids_column.sql`

```sql
-- Agregar columna destinos_ids a la tabla Paquete_Turismo
ALTER TABLE Paquete_Turismo 
ADD COLUMN destinos_ids VARCHAR(255) NULL;

-- Migrar datos existentes de id_destino a destinos_ids
UPDATE Paquete_Turismo 
SET destinos_ids = CAST(id_destino AS CHAR)
WHERE id_destino IS NOT NULL;
```

**Propósito:** Permitir que un paquete turístico incluya múltiples destinos.

---

## Datos de Prueba

### Usuarios de Prueba

```sql
-- Superadministrador
INSERT INTO Usuario (nombre, apellido, correo, contrasena, id_rol) VALUES
('Super', 'Admin', 'super@aquatour.com', '$2a$10$...', 1);

-- Administrador
INSERT INTO Usuario (nombre, apellido, correo, contrasena, id_rol) VALUES
('Admin', 'Aquatour', 'admin@aquatour.com', '$2a$10$...', 2);

-- Empleado
INSERT INTO Usuario (nombre, apellido, correo, contrasena, id_rol) VALUES
('Empleado', 'Test', 'empleado@aquatour.com', '$2a$10$...', 3);
```

### Destinos de Prueba

```sql
INSERT INTO Destino (nombre, pais, ciudad, descripcion, activo) VALUES
('Cartagena de Indias', 'Colombia', 'Cartagena', 'Ciudad amurallada...', TRUE),
('Machu Picchu', 'Perú', 'Cusco', 'Ciudadela inca...', TRUE),
('Cancún', 'México', 'Cancún', 'Playas paradisíacas...', TRUE);
```

---

## Backup y Restauración

### Backup Manual

```bash
# Backup completo
mysqldump -h HOST -u USER -p DATABASE > backup_aquatour_$(date +%Y%m%d).sql

# Backup solo estructura
mysqldump -h HOST -u USER -p --no-data DATABASE > schema_aquatour.sql

# Backup solo datos
mysqldump -h HOST -u USER -p --no-create-info DATABASE > data_aquatour.sql
```

### Restauración

```bash
# Restaurar desde backup
mysql -h HOST -u USER -p DATABASE < backup_aquatour_20251010.sql
```

### Backup Automático (Clever Cloud)

Clever Cloud realiza backups automáticos diarios en el plan gratuito con retención de 7 días.

---

## Consultas Útiles

### Estadísticas de Clientes por Asesor

```sql
SELECT 
  u.nombre,
  u.apellido,
  COUNT(c.id_cliente) as total_clientes
FROM Usuario u
LEFT JOIN Cliente c ON u.id_usuario = c.id_usuario
GROUP BY u.id_usuario
ORDER BY total_clientes DESC;
```

### Reservas Pendientes de Pago

```sql
SELECT 
  r.id_reserva,
  c.nombre,
  c.apellido,
  r.monto_total,
  r.monto_pagado,
  (r.monto_total - r.monto_pagado) as saldo_pendiente
FROM Reserva r
JOIN Cliente c ON r.id_cliente = c.id_cliente
WHERE r.monto_pagado < r.monto_total
  AND r.estado != 'Cancelada'
ORDER BY r.fecha_inicio;
```

### Cotizaciones por Estado

```sql
SELECT 
  estado,
  COUNT(*) as total,
  SUM(precio_total) as valor_total
FROM Cotizacion
GROUP BY estado
ORDER BY total DESC;
```

### Destinos Más Populares

```sql
SELECT 
  d.nombre,
  d.pais,
  COUNT(c.id_cotizacion) as cotizaciones
FROM Destino d
JOIN Paquete_Turismo p ON FIND_IN_SET(d.id_destino, p.destinos_ids) > 0
JOIN Cotizacion c ON p.id_paquete = c.id_paquete
GROUP BY d.id_destino
ORDER BY cotizaciones DESC
LIMIT 10;
```

---

## Próximas Mejoras

1. **Auditoría:** Tabla de logs para cambios importantes
2. **Soft Delete:** Columna `deleted_at` en lugar de eliminar físicamente
3. **Versionado:** Historial de cambios en cotizaciones y reservas
4. **Archivos:** Tabla para adjuntos (documentos, fotos)
5. **Notificaciones:** Tabla de notificaciones del sistema
6. **Configuración:** Tabla de configuraciones globales
7. **Moneda:** Soporte multi-moneda en precios
8. **Comisiones:** Tabla de comisiones por venta

---

**Fin de la documentación de Base de Datos**
