# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-10-10

### 🎉 Lanzamiento Inicial

Primera versión completa del sistema Aquatour CRM con frontend Flutter Web, backend Node.js y base de datos MySQL.

---

## Frontend (Flutter Web)

### ✅ Autenticación y Usuarios
- Sistema de login con email y contraseña
- Tres niveles de roles: Empleado, Administrador, Superadministrador
- Gestión completa de usuarios (CRUD)
- Control de acceso basado en roles y permisos
- Persistencia de sesión con localStorage
- Expiración automática de sesión (24 horas)
- Pantalla de edición de usuarios con validaciones

### ✅ Dashboard
- Dashboard diferenciado por rol (completo para admin, limitado para empleado)
- Módulos reordenables con drag & drop
- Persistencia del orden de módulos por usuario
- Header personalizado con gradiente corporativo
- Navegación fluida entre módulos
- Diseño responsive para móviles y desktop

### ✅ Módulos Implementados

**Clientes:**
- Lista de clientes con vista personal y global
- Formulario modal de captura con validaciones
- Campos: datos personales, contacto, fuente, nivel de interés
- Selector de fecha de nacimiento
- Integración con API REST

**Destinos:**
- Grid de destinos turísticos
- Crear/editar destinos
- Activar/desactivar destinos
- Campos: nombre, país, ciudad, descripción, imagen

**Paquetes Turísticos:**
- Lista de paquetes
- Soporte para múltiples destinos por paquete
- Gestión de precios, duración, itinerarios
- Campos de inclusiones y exclusiones

**Cotizaciones:**
- Crear cotizaciones para clientes
- Estados: Pendiente, Enviada, Aceptada, Rechazada, Expirada
- Vinculación con paquetes y clientes
- Fecha de expiración

**Reservas:**
- Gestión de reservas confirmadas
- Estados: Pendiente, Confirmada, Pagada, Cancelada, Completada
- Control de montos total y pagado
- Fechas de inicio y fin del viaje

**Pagos:**
- Registro de pagos por reserva
- Métodos: Efectivo, Tarjeta, Transferencia, PayPal, Otro
- Referencia de transacción
- Historial completo de pagos

**Proveedores:**
- Directorio de proveedores de servicios
- Tipos de servicio (Hotel, Transporte, Guía, etc.)
- Datos de contacto y ubicación

**Contactos:**
- Directorio general de contactos
- Información de empresa y cargo
- No necesariamente clientes

### ✅ Componentes Reutilizables
- `CustomButton` - Botón con gradiente corporativo
- `DashboardOptionCard` - Card interactiva con animaciones
- `ModuleScaffold` - Scaffold consistente para módulos
- `CurrencyInputFormatter` - Formateador de moneda
- `NumberFormatter` - Formateador de números
- `PermissionsHelper` - Helper de verificación de permisos

### ✅ Servicios
- `ApiService` - Cliente HTTP centralizado para API REST
- `AuthService` - Autenticación con backend
- `StorageService` - Persistencia local con localStorage
- `LocalStorageService` - Wrapper de localStorage para web

### ✅ Modelos de Datos
- `User` - Usuario con roles y permisos
- `Client` - Cliente con datos completos
- `Destination` - Destino turístico
- `TourPackage` - Paquete turístico
- `Quote` - Cotización con estados
- `Reservation` - Reserva con control de pagos
- `Payment` - Pago con métodos
- `Provider` - Proveedor de servicios
- `Contact` - Contacto general

### ✅ UI/UX
- Diseño moderno con colores corporativos (#3D1F6E, #fdb913)
- Tipografía Montserrat de Google Fonts
- Gradientes y sombras consistentes
- Animaciones de hover y transiciones
- Responsive design con breakpoints
- Estados vacíos informativos
- Validación de formularios en tiempo real
- Mensajes de error y éxito con SnackBar

---

## Backend (Node.js + Express)

### ✅ Arquitectura
- Patrón en 3 capas: Routes → Controllers → Services
- Separación de responsabilidades
- Manejo centralizado de errores
- Pool de conexiones MySQL optimizado

### ✅ API REST Endpoints

**Autenticación:**
- `POST /api/auth/login` - Login con email/contraseña

**Usuarios:**
- `GET /api/users` - Listar usuarios
- `GET /api/users/:id` - Obtener usuario
- `POST /api/users` - Crear usuario
- `PUT /api/users/:id` - Actualizar usuario
- `DELETE /api/users/:id` - Eliminar usuario
- `GET /api/users/check-email/:email` - Verificar email

**Clientes:**
- `GET /api/clients` - Listar clientes
- `GET /api/clients/user/:idUsuario` - Clientes de un usuario
- `GET /api/clients/:id` - Obtener cliente
- `POST /api/clients` - Crear cliente
- `PUT /api/clients/:id` - Actualizar cliente
- `DELETE /api/clients/:id` - Eliminar cliente

**Destinos:**
- `GET /api/destinations` - Listar destinos
- `GET /api/destinations/active` - Solo activos
- `GET /api/destinations/:id` - Obtener destino
- `POST /api/destinations` - Crear destino
- `PUT /api/destinations/:id` - Actualizar destino
- `DELETE /api/destinations/:id` - Eliminar destino

**Paquetes:**
- `GET /api/packages` - Listar paquetes
- `GET /api/packages/:id` - Obtener paquete
- `POST /api/packages` - Crear paquete
- `PUT /api/packages/:id` - Actualizar paquete
- `DELETE /api/packages/:id` - Eliminar paquete

**Cotizaciones:**
- `GET /api/quotes` - Listar cotizaciones
- `GET /api/quotes/:id` - Obtener cotización
- `POST /api/quotes` - Crear cotización
- `PUT /api/quotes/:id` - Actualizar cotización
- `DELETE /api/quotes/:id` - Eliminar cotización

**Reservas:**
- `GET /api/reservations` - Listar reservas
- `GET /api/reservations/client/:idCliente` - Reservas de cliente
- `GET /api/reservations/:id` - Obtener reserva
- `POST /api/reservations` - Crear reserva
- `PUT /api/reservations/:id` - Actualizar reserva
- `DELETE /api/reservations/:id` - Eliminar reserva

**Pagos:**
- `GET /api/payments` - Listar pagos
- `GET /api/payments/reservation/:idReserva` - Pagos de reserva
- `GET /api/payments/:id` - Obtener pago
- `POST /api/payments` - Crear pago
- `PUT /api/payments/:id` - Actualizar pago
- `DELETE /api/payments/:id` - Eliminar pago

**Proveedores:**
- `GET /api/providers` - Listar proveedores
- `GET /api/providers/:id` - Obtener proveedor
- `POST /api/providers` - Crear proveedor
- `PUT /api/providers/:id` - Actualizar proveedor
- `DELETE /api/providers/:id` - Eliminar proveedor

**Contactos:**
- `GET /api/contacts` - Listar contactos
- `GET /api/contacts/:id` - Obtener contacto
- `POST /api/contacts` - Crear contacto
- `PUT /api/contacts/:id` - Actualizar contacto
- `DELETE /api/contacts/:id` - Eliminar contacto

### ✅ Seguridad
- CORS configurado con orígenes permitidos
- Contraseñas hasheadas con bcrypt (10 rounds)
- Validación de entrada en controladores
- Prepared statements para prevenir SQL injection
- Contraseñas nunca devueltas en respuestas
- Verificación de usuarios activos en login

### ✅ Servicios
- `users.service.js` - Lógica de usuarios con mapeo de roles
- `password.service.js` - Hash y verificación de contraseñas
- `clients.service.js` - Lógica de clientes
- `destinations.service.js` - Lógica de destinos
- `packages.service.js` - Lógica de paquetes
- `quotes.service.js` - Lógica de cotizaciones
- `reservations.service.js` - Lógica de reservas
- `payments.service.js` - Lógica de pagos
- `providers.service.js` - Lógica de proveedores
- `contacts.service.js` - Lógica de contactos

### ✅ Utilidades
- `error-handler.js` - Middleware de manejo de errores
- Mapeo automático de roles DB ↔ App
- Mapeo de tipos de documento
- Mapeo de género
- Normalización de datos

---

## Base de Datos (MySQL 8.0)

### ✅ Tablas Implementadas
- `Rol` - Catálogo de roles del sistema
- `Usuario` - Usuarios del sistema (empleados y admins)
- `Cliente` - Clientes potenciales y confirmados
- `Destino` - Destinos turísticos
- `Paquete_Turismo` - Paquetes turísticos
- `Cotizacion` - Cotizaciones generadas
- `Reserva` - Reservas confirmadas
- `Pago` - Pagos realizados
- `Proveedor` - Proveedores de servicios
- `Contacto` - Contactos generales

### ✅ Características
- Relaciones con claves foráneas
- Índices en columnas de búsqueda frecuente
- Campos ENUM para estados y tipos
- Timestamps automáticos (created_at, updated_at)
- Soporte para múltiples destinos por paquete (destinos_ids)
- Validación de datos a nivel de BD

### ✅ Migraciones
- `add_destinos_ids_column.sql` - Múltiples destinos por paquete

---

## Despliegue y CI/CD

### ✅ Frontend - Vercel
- Despliegue automático con GitHub Actions
- Build personalizado con Flutter SDK
- CDN global para distribución
- HTTPS automático
- URL: `https://tour-crm.vercel.app`

### ✅ Backend - Clever Cloud
- Despliegue en Node.js runtime
- Auto-scaling según demanda
- Logs en tiempo real
- URL: `https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api`

### ✅ Base de Datos - Clever Cloud MySQL
- MySQL 8.0 en EU
- Backups automáticos diarios
- Pool de conexiones optimizado (3 conexiones)
- 256 MB de almacenamiento

### ✅ GitHub Actions
- Workflow de deploy automático en push a main
- Integración con Vercel CLI
- Variables de entorno seguras con GitHub Secrets

---

## Documentación

### ✅ Documentación Técnica Completa
- `DOCUMENTACION_FRONTEND.md` - Arquitectura y componentes del frontend
- `DOCUMENTACION_BACKEND.md` - API REST y servicios del backend
- `DOCUMENTACION_BASE_DATOS.md` - Estructura de BD y relaciones
- `DOCUMENTACION_DESPLIEGUE.md` - Guía de despliegue y CI/CD
- `README.md` - Documentación general del proyecto
- `README_API.md` - Documentación de API REST
- `blueprint.md` - Blueprint del proyecto

---

## Configuración

### ✅ Variables de Entorno
- `.env` - Variables de producción
- `.env.local` - Variables de desarrollo local
- `.env.example` - Plantilla de variables

### ✅ Archivos de Configuración
- `vercel.json` - Configuración de Vercel
- `build.sh` - Script de build personalizado
- `pubspec.yaml` - Dependencias de Flutter
- `package.json` - Dependencias de Node.js
- `nodemon.json` - Configuración de nodemon

---

## Dependencias

### Frontend
- `flutter` - Framework principal
- `google_fonts` - Tipografía Montserrat
- `form_field_validator` - Validación de formularios
- `http` - Cliente HTTP
- `provider` - Gestión de estado (preparado)
- `flutter_dotenv` - Variables de entorno
- `json_annotation` - Serialización JSON
- `fl_chart` - Gráficas
- `intl` - Internacionalización

### Backend
- `express` - Framework web
- `mysql2` - Cliente MySQL con promesas
- `bcryptjs` - Hash de contraseñas
- `cors` - Middleware CORS
- `dotenv` - Variables de entorno
- `nodemon` - Auto-reload en desarrollo

---

## Próximas Mejoras

### 🔮 Funcionalidades
- [ ] Autenticación JWT
- [ ] Middleware de autorización por roles
- [ ] Sistema de notificaciones
- [ ] Reportes y analytics
- [ ] Exportación a PDF/Excel
- [ ] Búsqueda avanzada y filtros
- [ ] Paginación en listados
- [ ] Cache con Redis
- [ ] Modo oscuro
- [ ] Internacionalización (i18n)
- [ ] PWA completo con offline support

### 🔮 Técnicas
- [ ] Tests unitarios (Jest, Flutter Test)
- [ ] Tests de integración (Supertest, Playwright)
- [ ] Documentación con Swagger/OpenAPI
- [ ] Logs estructurados con Winston
- [ ] Monitoreo con Sentry
- [ ] CI/CD con tests automáticos
- [ ] Migración a Provider/Riverpod
- [ ] Optimización de queries SQL
- [ ] Soft delete en lugar de eliminación física
- [ ] Auditoría de cambios

---

## Créditos

**Desarrollado para:** Aquatour  
**Stack:** Flutter Web + Node.js + Express + MySQL  
**Despliegue:** Vercel + Clever Cloud  
**Versión:** 1.0.0  
**Fecha:** Octubre 2025
