# Aquatour CRM - Frontend

Aplicación web de gestión de empleados y CRM para Aquatour, desarrollada con Flutter Web.

## Características

- Sistema de autenticación de usuarios con roles y permisos
- Gestión completa de usuarios (CRUD)
- Interfaz moderna y responsiva con colores corporativos
- Almacenamiento local con localStorage (temporal hasta implementación de API REST)
- Sistema de roles: Empleado, Administrador, Superadministrador

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

El archivo `.env` contiene configuración opcional. Si no existe, créalo:

```
# URL de tu API REST (cuando esté lista)
API_BASE_URL=https://your-api-url.cleverapps.io/api

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

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── login_screen.dart           # Pantalla de login
├── dashboard_screen.dart       # Dashboard principal
├── user_management_screen.dart # Gestión de usuarios
└── services/
    └── storage_service.dart    # Servicio de almacenamiento local
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

La aplicación está configurada para desplegarse automáticamente en GitHub Pages mediante GitHub Actions. Simplemente haz push a la rama `main`.

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

### 🚧 Próximos Módulos
- Cotizaciones
- Reservas
- Contactos
- Empresas
- Historial de pagos

## Estado del Desarrollo

### ✅ Completado
- [x] Configuración del proyecto Flutter Web
- [x] Sistema de autenticación con roles
- [x] Gestión completa de usuarios
- [x] Almacenamiento local funcional
- [x] UI moderna y responsive
- [x] Despliegue en GitHub Pages

### 🔄 Pendiente
- [ ] Implementación de API REST en Python
- [ ] Conexión con base de datos MySQL
- [ ] Módulos de negocio (Cotizaciones, Reservas, etc.)
- [ ] Mejoras en UX/UI

## Contribución

1. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
2. Realiza tus cambios y prueba
3. Haz commit: `git commit -m 'Agrega nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crea un Pull Request

## Soporte

Para soporte técnico, contacta al equipo de desarrollo.

---

**Versión**: 1.0.0  
**Última actualización**: Septiembre 2024
