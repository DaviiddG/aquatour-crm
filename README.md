# Aquatour CRM

Aplicación CRM de Aquatour con frontend en Flutter Web y backend en Node.js + MySQL desplegado en Clever Cloud. Este documento resume el blueprint actual del proyecto, la arquitectura de ambos lados y los pasos para ejecutar o desplegar.

## Características Clave

- Gestión de autenticación con control de roles (Empleado, Administrador, Superadministrador).
- Dashboards diferenciados por rol (`DashboardScreen`, `LimitedDashboardScreen`) con UI responsiva.
- **Orden personalizable de módulos** con drag & drop y persistencia por usuario en `localStorage`.
- Persistencia de sesión en `localStorage` mediante `StorageService` y restablecimiento automático tras recargar.
- Módulo de gestión de usuarios (CRUD) disponible para administradores.
- Pantallas de Clientes, Destinos y Paquetes alineadas al estilo del panel mediante `ModuleScaffold`.
- Formulario modal de captura de clientes (pendiente de integración con API) en `ClientListScreen`.
- Configuración dinámica de `API_BASE_URL` soportando `--dart-define`, archivos `.env` y detección automática de origen web.

## Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión 3.13.0 o superior)
- Un navegador web moderno (Chrome, Firefox, Safari, Edge)

## Instalación y Configuración

### 1. Clona el repositorio

```bash
git clone [URL_DEL_REPOSITORIO]
cd aquatour
```

### 2. Instala las dependencias

```bash
flutter pub get
```

### 3. Configura las variables de entorno (opcional)

El archivo `.env` contiene configuración opcional para Flutter Web. Si no existe, créalo:

```
# URL de tu API REST (cuando esté lista)
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api

# Configuración de la aplicación
APP_ENV=development
DEBUG=true
```

### 4. Ejecuta la aplicación

#### Para desarrollo (recomendado):
```bash
flutter run -d web
```

Esto abrirá la aplicación en tu navegador predeterminado en `http://localhost:PORT`.

#### Para producción (construir y servir):
```bash
flutter build web --release
```

Los archivos construidos estarán en `build/web/`. Puedes servirlos con cualquier servidor web estático como:
- `python -m http.server 8000` (desde la carpeta build/web)
- Nginx, Apache, etc.

## Arquitectura General

- **Frontend** (`lib/`): Flutter Web con widgets especializados, servicios compartidos y modelos. Maneja autenticación, dashboards y formularios.
- **Backend** (`server/src/`): Express + MySQL con capas separadas de rutas, controladores y servicios. Actualmente expone autenticación y CRUD de usuarios.
- **Despliegue**: Frontend en Vercel (`tour-crm.vercel.app`), backend en Clever Cloud (`https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api`). GitHub Actions automatiza build y deploy.

## Arquitectura del Frontend

- **Capas y flujo general**
  - El punto de entrada `lib/main.dart` inicializa variables (`dotenv`) y servicios, construye `MyApp` con tema extendido y navega mediante `_SessionGate` dependiendo del estado de sesión almacenado en `StorageService`.
  - La navegación principal se basa en `MaterialPageRoute` empujada desde cards del dashboard; no se usa `Navigator 2.0`, pero la jerarquía modular permite añadirlo en el futuro.

- **Gestión de estado y sesión**
  - `lib/services/storage_service.dart` actúa como capa de persistencia (singleton). Usa `shared_preferences`/`localStorage` para web vía `window.localStorage` y mantiene `currentUser`, `token` y expiración (`lastActivity`).
  - Expone métodos síncronos/asíncronos: `initializeData()`, `login()`, `logout()`, `getCurrentUser()`, `isSessionActive()`. `_SessionGate` consulta `getCurrentUser()` en `initState()` para decidir la pantalla inicial.
  - `lib/services/api_service.dart` encapsula `http.Client`; gestiona cabeceras comunes (JSON, token), normaliza la URL base con `_normalizeBaseUrl` y maneja errores transformándolos en excepciones con mensaje legible.

- **UI base y tema**
  - `MyApp` define `ThemeData` corporativo (colores `Color(0xFF3D1F6E)` y `Color(0xFFfdb913)`), tipografía Montserrat, `InputDecorationTheme` con bordes redondeados y estilos personalizados para `ElevatedButton` y `TextButton`.

- **Autenticación (`lib/login_screen.dart`)**
  - StatefulWidget con `GlobalKey<FormState>`, controladores para email y contraseña, y estado `_isLoading`.
  - Usa `form_field_validator` para reglas de negocio y `CustomButton` (en `lib/widgets/custom_button.dart`) para el CTA de login.
  - Tras `StorageService.login()`, decide destino (`DashboardScreen` o `LimitedDashboardScreen`) según `user.esAdministrador`.

- **Dashboards y navegación modular**
  - `lib/dashboard_screen.dart` define `DashboardModule` (id, título, descripción, icono, builder, roles permitidos). `_getModulesForUser()` filtra módulos por `UserRole` y combina el resultado con el orden almacenado en `StorageService`.
  - Se usa `FutureBuilder` para leer al usuario actual y `ReorderableListView` para permitir drag & drop, disparando `StorageService.saveDashboardOrder()` tras cada reordenamiento.
  - `_DashboardHeader` entrega saludo personalizado con gradiente y CTA informativa; se ajusta según anchura (`isCompact`).
  - `lib/limited_dashboard_screen.dart` replica el patrón con `_LimitedModule`, permite ordenar accesos del empleado con `ReorderableListView` y mantiene cabecera `_LimitedHeader`. El AppBar detecta `isNarrow` para reemplazar `TextButton.icon` por `IconButton`, evitando solapamiento en móviles.
  - `lib/widgets/dashboard_option_card.dart` encapsula cada atajo: `AnimatedScale` y `AnimatedContainer` manejan el hover; el contenido se organiza con `Row` + `Expanded` y un botón `TextButton.icon` alineado a la derecha.

- **Módulo de clientes**
  - `lib/screens/client_list_screen.dart` es `StatefulWidget` con `showAll` como prop para diferenciar vista personal vs. global. Usa `ModuleScaffold` para replicar la experiencia del dashboard y un `FloatingActionButton` que abre `_ClientFormSheet`.
  - `_ClientFormSheet` gestiona formularios con `GlobalKey<FormState>`, controladores y selección de fecha (`showDatePicker`). Incluye campos `DropdownButtonFormField` para fuente de contacto/interés y textareas para observaciones. Actualmente emite `SnackBar` temporal hasta contar con API.
- **Destinos y Paquetes turísticos**
  - `lib/screens/destinations_screen.dart` y `lib/screens/tour_packages_screen.dart` adoptan `ModuleScaffold`, muestran tarjetas resumen y estados vacíos alineados con la marca.
  - El botón "Nuevo paquete" informa que la función está en desarrollo mediante `SnackBar`.

- **Pantallas adicionales y reutilización**
  - Directorio `lib/screens/` alberga módulos como `quotes_screen.dart`, `reservations_screen.dart`, `destinations_screen.dart`, `tour_packages_screen.dart`. Muchos son placeholders con estructura base para expandirse.
  - `user_management_screen.dart` ofrece CRUD de usuarios, integrándose con `StorageService` y `ApiService` para listados y acciones administrativas.
  - Componentes reutilizables (p.ej. `custom_button.dart`, `empty_state_widget.dart`) homogenizan la experiencia visual.

- **Responsividad y estilos**
  - Conjuntos comunes: `EdgeInsets` reducidos para pantallas pequeñas, `MediaQuery` en cabeceras y `_columnsForWidth()`/`_aspectRatioForWidth()` para ajustar grillas.
  - Uso consistente de `BoxShadow`, gradientes y bordes redondeados para mantener lineamientos de marca.

- **Futuras extensiones**
  - La arquitectura permite incluir `Provider` o `Riverpod` si se necesita estado global. Actualmente `provider` está instalado pero se usa mínimamente; se proyecta ampliar cuando los módulos de negocio requieran sincronización compleja.

## Arquitectura del Backend

- **Vista general**
  - El backend reside en `server/src/` y sigue un patrón en capas: rutas → controladores → servicios → base de datos. Cada capa se aísla para facilitar pruebas y evolución.
  - Express expone la API REST bajo `/api`. Las respuestas se estandarizan con un objeto `{ ok: boolean, data | error }`.

- **Servidor y configuración global**
  - `server/src/server.js` inicializa Express, aplica `cors` con orígenes leídos de `process.env.CORS_ORIGIN`, y habilita parseo JSON/`urlencoded`.
  - Registra un endpoint de observabilidad `GET /api/health` y monta rutas `authRoutes` y `userRoutes`. `errorHandler` captura excepciones al final del pipeline.
  - Variables sensibles (`DB_HOST`, `DB_USER`, `API_BASE_URL`, etc.) provienen de Clever Cloud y `.env`; nunca se exponen en el repositorio.

- **Acceso a base de datos**
  - `server/src/config/db.js` crea un pool MySQL con `mysql2/promise`. Se establece `connectionLimit: 3` para acoplarse al límite de Clever Cloud.
  - Expone la función `query(sql, params)` que devuelve `[rows]`; los servicios la reutilizan para evitar duplicar lógica de conexión.
  - Las columnas se normalizan a camelCase mediante utilidades en `server/src/services/users.service.js` (`mapDbUser`).

- **Flujo de petición (ejemplo login)**
  - Ruta `POST /api/auth/login` definida en `server/src/routes/auth.routes.js`.
  - Controlador `login()` (`server/src/controllers/auth.controller.js`) valida `email/password`, consulta al servicio y construye la respuesta HTTP.
  - Servicio `findByEmail()` (`server/src/services/users.service.js`) ejecuta `SELECT` parametrizado, protege contra SQL injection y devuelve el registro.
  - `verifyPassword()` (`server/src/services/password.service.js`) compara hash bcrypt o texto plano; si es válido, el controlador envía `user` sin `contrasena`.

- **Flujo de CRUD de usuarios**
  - `server/src/routes/users.routes.js` reúne endpoints `GET /`, `GET /:idUsuario`, `POST /`, `PUT /:idUsuario`, `DELETE /:idUsuario`, y `GET /check-email/:email`.
  - `server/src/controllers/users.controller.js` aplica reglas de negocio: previene duplicados (`checkEmail`), maneja códigos HTTP (`404`, `409`) y delega a los servicios.
  - `server/src/services/users.service.js` implementa operaciones SQL (`findAllUsers`, `createUser`, `updateUser`, `deleteUser`). Cada método actualiza campos como `nombre`, `rol`, `activo`, y transforma fechas `Date` a ISO antes de responder.
  - Interpreta el campo `rol` para mapear a `UserRole` (enum compartido con Flutter) y garantiza que `activo` sea booleano.

- **Manejo de errores y logging**
  - `server/src/utils/error-handler.js` centraliza la captura de errores asincrónicos; registra con prefijo `❌ API Error` y responde con mensaje seguro.
  - Los servicios arrojan `Error` con `status` opcional para personalizar el código HTTP (p.ej. `status=404`).

- **Dependencias clave**
  - `express`, `cors`, `mysql2`, `dotenv` para configuración; `bcryptjs` (incluido vía `password.service`) para hashing.
  - Scripts de `package.json` contemplan `npm run start` (producción) y `npm run dev` con `nodemon`.

- **Seguridad y próximos pasos**
  - Actualmente la autenticación es sin token; se planea añadir middleware JWT que valide sesiones en rutas `/api/users`.
  - La tabla `Cliente` (campos `id_cliente`, `id_usuario`, `nacionalidad`, etc.) aún no cuenta con endpoints. Se prevé crear `clients.routes.js`, `clients.controller.js` y `clients.service.js` siguiendo el mismo patrón en capas.
  - Monitoreo adicional (logs estructurados, alertas) y tests (Jest + Supertest) están sugeridos para la siguiente iteración.

## Estructura de Carpetas (resumen)

```
lib/
├── main.dart
├── login_screen.dart
├── dashboard_screen.dart
├── limited_dashboard_screen.dart
├── screens/
│   ├── client_list_screen.dart
│   ├── destinations_screen.dart
│   └── …
├── services/
│   ├── api_service.dart
│   └── storage_service.dart
└── widgets/
    └── dashboard_option_card.dart

server/src/
├── config/db.js
├── controllers/
│   ├── auth.controller.js
│   └── users.controller.js
├── routes/
│   ├── auth.routes.js
│   └── users.routes.js
├── services/
│   ├── password.service.js
│   └── users.service.js
├── utils/error-handler.js
└── server.js
```

## Usuarios de Prueba

La aplicación incluye usuarios de prueba que se inicializan automáticamente al primer inicio:

- **Superadministrador**: super@aquatour.com / super123
- **Administrador**: admin@aquatour.com / admin123
- **Empleado**: empleado@aquatour.com / empleado123

## Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.3.1
  form_field_validator: ^1.1.0
  http: ^1.1.0
  provider: ^6.1.1
  flutter_dotenv: ^5.1.0
  json_annotation: ^4.8.1
```

## Despliegue Automático

- `flutter-ci.yml`: compila Flutter Web con `flutter build web --release --dart-define=API_BASE_URL=...`.
- `deploy.yml`: instala Vercel CLI y publica en `tour-crm.vercel.app` usando los secretos `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `API_BASE_URL`.
- Backend desplegado en Clever Cloud; actualiza la variable `API_BASE_URL` en Vercel para apuntar al entorno productivo.

## Funcionalidades Implementadas

### ✅ Sistema de Autenticación
- Login con email/contraseña
- Control de acceso basado en roles
- Persistencia de sesión

### ✅ Gestión de Usuarios
- Crear, editar, eliminar usuarios
- Asignación de roles
- Vista de detalles de usuario

### ✅ Interfaz de Usuario
- Diseño moderno con colores corporativos
- Responsive design
- Animaciones y efectos visuales
- Formulario modal de clientes con validaciones básicas (integración con API pendiente)
- **Dashboard reordenable con persistencia por usuario**
- **Pantallas de Clientes, Destinos y Paquetes unificadas con `ModuleScaffold`**

### ✅ Backend Actual
- API de autenticación (`POST /api/auth/login`)
- CRUD de usuarios (`/api/users`)
- Pool MySQL configurado para Clever Cloud

### 🚧 Próximos Módulos
- Cotizaciones
- Reservas
- Contactos
- Empresas
- Historial de pagos
- API de clientes y conexión con el formulario Flutter
- Middleware de autenticación y auditoría de acciones

## Estado del Desarrollo

### ✅ Completado
- [x] Configuración del proyecto Flutter Web
- [x] Sistema de autenticación con roles
- [x] Gestión completa de usuarios
- [x] Almacenamiento local y persistencia de sesión
- [x] UI moderna y responsive
- [x] Despliegue en Vercel (frontend) y Clever Cloud (backend)

### 🔄 Pendiente
- [ ] Endpoints de clientes y sincronización con base de datos
- [ ] Módulos funcionales de cotizaciones, reservas e indicadores
- [ ] Refactorización de seguridad (JWT, roles en backend)
- [ ] Mejoras adicionales de UX/UI

## Contribución

1. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
2. Realiza tus cambios y prueba
3. Haz commit: `git commit -m 'Agrega nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crea un Pull Request

## Soporte

Para soporte técnico, contacta al equipo de desarrollo.

---

**Versión**: 1.1.0  
**Última actualización**: Septiembre 2025
