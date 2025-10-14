# Documentación Técnica - Frontend Flutter

**Proyecto:** Aquatour CRM  
**Versión:** 1.0.0  
**Última actualización:** Octubre 2025  
**Tecnología:** Flutter Web

---

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Estructura de Directorios](#estructura-de-directorios)
3. [Modelos de Datos](#modelos-de-datos)
4. [Servicios](#servicios)
5. [Pantallas Principales](#pantallas-principales)
6. [Widgets Reutilizables](#widgets-reutilizables)
7. [Sistema de Autenticación](#sistema-de-autenticación)
8. [Sistema de Roles y Permisos](#sistema-de-roles-y-permisos)
9. [Gestión de Estado](#gestión-de-estado)
10. [Configuración y Variables de Entorno](#configuración-y-variables-de-entorno)

---

## Arquitectura General

### Stack Tecnológico
- **Framework:** Flutter 3.9.0+
- **Lenguaje:** Dart
- **Plataforma:** Web (con soporte para desktop)
- **Gestión de Estado:** StatefulWidget + Provider (preparado)
- **HTTP Client:** package:http
- **Persistencia Local:** localStorage (web) via StorageService

### Patrón de Arquitectura
El proyecto sigue una arquitectura en capas:

```
Presentación (UI)
    ↓
Servicios (Business Logic)
    ↓
Modelos (Data Models)
    ↓
API / Storage
```

---

## Estructura de Directorios

```
lib/
├── main.dart                          # Punto de entrada
├── data/
│   └── countries_cities.dart          # Datos estáticos de países y ciudades
├── models/                            # Modelos de datos
│   ├── user.dart                      # Usuario y roles
│   ├── client.dart                    # Cliente
│   ├── contact.dart                   # Contacto
│   ├── destination.dart               # Destino turístico
│   ├── tour_package.dart              # Paquete turístico
│   ├── quote.dart                     # Cotización
│   ├── reservation.dart               # Reserva
│   ├── payment.dart                   # Pago
│   └── provider.dart                  # Proveedor
├── screens/                           # Pantallas de módulos
│   ├── client_list_screen.dart        # Lista de clientes
│   ├── client_edit_screen.dart        # Editar cliente
│   ├── destinations_screen.dart       # Destinos
│   ├── destination_edit_screen.dart   # Editar destino
│   ├── tour_packages_screen.dart      # Paquetes turísticos
│   ├── package_edit_screen.dart       # Editar paquete
│   ├── payments_screen.dart           # Pagos
│   ├── payment_edit_screen.dart       # Editar pago
│   ├── quote_edit_screen.dart         # Editar cotización
│   └── reservation_edit_screen.dart   # Editar reserva
├── services/                          # Capa de servicios
│   ├── api_service.dart               # Cliente HTTP para API REST
│   ├── auth_service.dart              # Servicio de autenticación
│   ├── storage_service.dart           # Persistencia local
│   └── local_storage_service.dart     # Wrapper de localStorage
├── utils/                             # Utilidades
│   ├── currency_input_formatter.dart  # Formateador de moneda
│   ├── number_formatter.dart          # Formateador de números
│   └── permissions_helper.dart        # Helper de permisos
├── widgets/                           # Componentes reutilizables
│   ├── custom_button.dart             # Botón personalizado
│   ├── dashboard_option_card.dart     # Card de opción del dashboard
│   └── module_scaffold.dart           # Scaffold para módulos
├── dashboard_screen.dart              # Dashboard administrador
├── limited_dashboard_screen.dart      # Dashboard empleado
├── login_screen.dart                  # Pantalla de login
├── user_management_screen.dart        # Gestión de usuarios
├── user_edit_screen.dart              # Editar usuario
├── quotes_screen.dart                 # Pantalla de cotizaciones
├── reservations_screen.dart           # Pantalla de reservas
├── contacts_screen.dart               # Pantalla de contactos
├── companies_screen.dart              # Pantalla de empresas
├── providers_screen.dart              # Pantalla de proveedores
├── payment_history_screen.dart        # Historial de pagos
└── performance_indicators_screen.dart # Indicadores de rendimiento
```

---

## Modelos de Datos

### User (Usuario)
**Archivo:** `lib/models/user.dart`

```dart
enum UserRole {
  empleado,
  administrador,
  superadministrador
}

class User {
  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String email;
  final UserRole rol;
  final String tipoDocumento;
  final String numDocumento;
  final DateTime fechaNacimiento;
  final String genero;
  final String telefono;
  final String direccion;
  final String ciudadResidencia;
  final String paisResidencia;
  final String contrasena;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Características:**
- Enum `UserRole` con 3 niveles de acceso
- Métodos de conversión: `fromMap()`, `toMap()`
- Getters calculados: `nombreCompleto`, `edad`
- Verificadores de permisos: `esAdministrador`, `puedeGestionarUsuarios`, etc.

### Client (Cliente)
**Archivo:** `lib/models/client.dart`

```dart
class Client {
  final int? idCliente;
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String nacionalidad;
  final String tipoDocumento;
  final String numDocumento;
  final DateTime? fechaNacimiento;
  final String? genero;
  final String? direccion;
  final String? ciudad;
  final String? pais;
  final String? fuenteContacto;
  final String? nivelInteres;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Destination (Destino)
**Archivo:** `lib/models/destination.dart`

```dart
class Destination {
  final int? idDestino;
  final String nombre;
  final String pais;
  final String ciudad;
  final String descripcion;
  final String? imagenUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### TourPackage (Paquete Turístico)
**Archivo:** `lib/models/tour_package.dart`

```dart
class TourPackage {
  final int? idPaquete;
  final String nombre;
  final String descripcion;
  final int duracionDias;
  final double precioBase;
  final String? destinosIds;  // IDs separados por comas (ej: "1,3,5")
  final String? itinerario;
  final String? incluye;
  final String? noIncluye;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Quote (Cotización)
**Archivo:** `lib/models/quote.dart`

```dart
enum QuoteStatus {
  pendiente,
  enviada,
  aceptada,
  rechazada,
  expirada
}

class Quote {
  final int? idCotizacion;
  final int idCliente;
  final int idUsuario;
  final int? idPaquete;
  final DateTime fechaCotizacion;
  final DateTime? fechaViaje;
  final int numPersonas;
  final double precioTotal;
  final QuoteStatus estado;
  final String? observaciones;
  final DateTime? fechaExpiracion;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Reservation (Reserva)
**Archivo:** `lib/models/reservation.dart`

```dart
enum ReservationStatus {
  pendiente,
  confirmada,
  pagada,
  cancelada,
  completada
}

class Reservation {
  final int? idReserva;
  final int idCliente;
  final int idCotizacion;
  final int idUsuario;
  final DateTime fechaReserva;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int numPersonas;
  final double montoTotal;
  final double montoPagado;
  final ReservationStatus estado;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Payment (Pago)
**Archivo:** `lib/models/payment.dart`

```dart
enum PaymentMethod {
  efectivo,
  tarjeta,
  transferencia,
  paypal,
  otro
}

class Payment {
  final int? idPago;
  final int idReserva;
  final double monto;
  final DateTime fechaPago;
  final PaymentMethod metodoPago;
  final String? referencia;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## Servicios

### ApiService
**Archivo:** `lib/services/api_service.dart`

Cliente HTTP centralizado para todas las peticiones a la API REST.

**Características:**
- Singleton pattern
- Manejo automático de headers (Content-Type, Authorization)
- Normalización de URL base
- Manejo de errores HTTP
- Métodos: `get()`, `post()`, `put()`, `delete()`

**Ejemplo de uso:**
```dart
final response = await ApiService().get('/users');
final users = (response['data'] as List)
    .map((u) => User.fromMap(u))
    .toList();
```

### StorageService
**Archivo:** `lib/services/storage_service.dart`

Servicio de persistencia local usando localStorage para web.

**Características:**
- Singleton pattern
- Gestión de sesión de usuario
- Almacenamiento de token
- Control de expiración de sesión
- Persistencia de preferencias (orden de dashboard)

**Métodos principales:**
```dart
Future<void> initializeData()
Future<void> login(User user, String token)
Future<void> logout()
User? getCurrentUser()
bool isSessionActive()
Future<void> saveDashboardOrder(List<String> order)
List<String> getDashboardOrder()
```

### AuthService
**Archivo:** `lib/services/auth_service.dart`

Servicio de autenticación que conecta con la API.

**Métodos:**
```dart
Future<Map<String, dynamic>> login(String email, String password)
Future<void> logout()
```

---

## Pantallas Principales

### LoginScreen
**Archivo:** `lib/login_screen.dart`

Pantalla de inicio de sesión con validación de formularios.

**Características:**
- Validación de email y contraseña
- Toggle de visibilidad de contraseña
- Integración con `AuthService`
- Redirección basada en rol
- Manejo de errores con SnackBar

### DashboardScreen (Administrador)
**Archivo:** `lib/dashboard_screen.dart`

Dashboard completo con todos los módulos del CRM.

**Características:**
- Módulos reordenables con drag & drop
- Persistencia del orden por usuario
- Filtrado de módulos por rol
- Header con gradiente corporativo
- Navegación a módulos específicos
- Botón de logout

**Módulos disponibles:**
- Clientes
- Cotizaciones
- Reservas
- Destinos
- Paquetes Turísticos
- Pagos
- Proveedores
- Contactos
- Empresas
- Gestión de Usuarios
- Indicadores de Rendimiento

### LimitedDashboardScreen (Empleado)
**Archivo:** `lib/limited_dashboard_screen.dart`

Dashboard limitado para empleados.

**Módulos disponibles:**
- Clientes (solo propios)
- Cotizaciones
- Reservas
- Contactos

### UserManagementScreen
**Archivo:** `lib/user_management_screen.dart`

Gestión completa de usuarios (CRUD).

**Características:**
- Lista de usuarios con búsqueda
- Filtro por rol y estado
- Crear nuevo usuario
- Editar usuario existente
- Activar/desactivar usuarios
- Integración con API REST

### ClientListScreen
**Archivo:** `lib/screens/client_list_screen.dart`

Lista y gestión de clientes.

**Características:**
- Vista de todos los clientes o solo propios
- Formulario modal de captura
- Validación de campos
- Selector de fecha de nacimiento
- Dropdown de fuente de contacto y nivel de interés
- Integración con API

### DestinationsScreen
**Archivo:** `lib/screens/destinations_screen.dart`

Gestión de destinos turísticos.

**Características:**
- Grid de destinos con imágenes
- Crear/editar destinos
- Activar/desactivar destinos
- Búsqueda y filtros

### TourPackagesScreen
**Archivo:** `lib/screens/tour_packages_screen.dart`

Gestión de paquetes turísticos.

**Características:**
- Lista de paquetes
- Soporte para múltiples destinos por paquete
- Gestión de precios y duración
- Itinerarios detallados
- Campos de inclusiones y exclusiones

---

## Widgets Reutilizables

### CustomButton
**Archivo:** `lib/widgets/custom_button.dart`

Botón personalizado con gradiente corporativo.

**Propiedades:**
```dart
final String text;
final VoidCallback onPressed;
final bool isLoading;
final Color? backgroundColor;
final double? width;
```

### DashboardOptionCard
**Archivo:** `lib/widgets/dashboard_option_card.dart`

Card interactiva para opciones del dashboard.

**Características:**
- Animación de hover
- Gradiente de fondo
- Icono y descripción
- Navegación al hacer clic

### ModuleScaffold
**Archivo:** `lib/widgets/module_scaffold.dart`

Scaffold reutilizable para módulos.

**Características:**
- AppBar consistente
- Botón de retroceso
- Área de contenido
- FAB opcional

---

## Sistema de Autenticación

### Flujo de Autenticación

1. **Login:**
   - Usuario ingresa email y contraseña
   - `LoginScreen` valida el formulario
   - `AuthService.login()` envía credenciales a API
   - API valida y retorna usuario + token
   - `StorageService.login()` guarda sesión
   - Redirección según rol

2. **Persistencia de Sesión:**
   - Al iniciar la app, `main.dart` verifica sesión
   - `StorageService.getCurrentUser()` recupera usuario
   - Si existe y no expiró, redirige al dashboard
   - Si no existe, muestra login

3. **Logout:**
   - Usuario hace clic en logout
   - `StorageService.logout()` limpia datos
   - Redirección a login

### Expiración de Sesión
- Tiempo de expiración: 24 horas
- Se verifica en cada inicio de app
- Se actualiza `lastActivity` en cada login

---

## Sistema de Roles y Permisos

### Roles Disponibles

1. **Empleado:**
   - Acceso limitado
   - Solo ve sus propios clientes
   - Puede crear cotizaciones y reservas
   - No puede gestionar usuarios

2. **Administrador:**
   - Acceso completo a módulos
   - Puede gestionar usuarios
   - Ve todos los clientes
   - Acceso a reportes

3. **Superadministrador:**
   - Control total del sistema
   - Puede configurar sistema
   - Todos los permisos de administrador

### Implementación de Permisos

**En el modelo User:**
```dart
bool get esAdministrador => 
    rol == UserRole.administrador || 
    rol == UserRole.superadministrador;

bool get puedeGestionarUsuarios => esAdministrador;
bool get puedeVerTodosLosModulos => esAdministrador;
bool get puedeEliminarDatos => esAdministrador;
bool get puedeConfigurarSistema => esSuperAdministrador;
```

**En las pantallas:**
```dart
if (currentUser.puedeGestionarUsuarios) {
  // Mostrar opción de gestión de usuarios
}
```

---

## Gestión de Estado

### Enfoque Actual
- **StatefulWidget** para pantallas con estado local
- **setState()** para actualizaciones de UI
- **FutureBuilder** para datos asíncronos
- **StreamBuilder** (preparado para uso futuro)

### Provider (Preparado)
El paquete `provider` está instalado pero no se usa extensivamente aún. Está preparado para:
- Estado global de usuario
- Sincronización de datos
- Notificaciones en tiempo real

---

## Configuración y Variables de Entorno

### Archivos de Configuración

**`.env`:**
```
API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
APP_ENV=production
DEBUG=false
```

**`.env.local`:**
```
API_BASE_URL=http://localhost:8080/api
```

### Uso en el Código

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env");
final apiUrl = dotenv.env['API_BASE_URL'];
```

### Compilación con Variables

**Desarrollo local:**
```bash
flutter run -d web-server --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080/api
```
Acceder en: `http://localhost:3000`

**Build para producción:**
```bash
flutter build web --release --dart-define=API_BASE_URL=https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api
```

---

## Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.3.1           # Tipografía Montserrat
  form_field_validator: ^1.1.0   # Validación de formularios
  http: ^1.1.0                   # Cliente HTTP
  provider: ^6.1.1               # Gestión de estado
  flutter_dotenv: ^5.1.0         # Variables de entorno
  json_annotation: ^4.8.1        # Serialización JSON
  fl_chart: ^0.68.0              # Gráficas
  equatable: ^2.0.5              # Comparación de objetos
  intl: ^0.20.2                  # Internacionalización
```

---

## Tema y Estilos

### Colores Corporativos

```dart
const Color colorPrimario = Color(0xFF3D1F6E);  // Morado Aquatour
const Color colorAcento = Color(0xFFfdb913);    // Naranja Aquatour
```

### Tipografía

```dart
GoogleFonts.montserratTextTheme()
```

### Componentes con Gradiente

```dart
LinearGradient(
  colors: [Color(0xFFfdb913), Color(0xFFf7941e)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## Responsividad

### Breakpoints

```dart
bool isCompact = MediaQuery.of(context).size.width < 600;
bool isNarrow = MediaQuery.of(context).size.width < 800;
```

### Adaptación de UI

- Grid columns ajustables según ancho
- Padding reducido en móviles
- AppBar compacto en pantallas pequeñas
- Formularios de una columna en móvil

---
