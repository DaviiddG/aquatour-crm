# Blueprint: Aquatour App

## Visión General

Esta es una aplicación interna para los empleados de la empresa Aquatour. La aplicación servirá como un CRM para la gestión de clientes. La primera fase del desarrollo se centra en la creación de una experiencia de autenticación de usuario segura y exclusiva para empleados.

## Diseño y Características Implementadas

### Paleta de Colores (Revisada)
- **Primario (Morado Aquatour):** `#3D1F6E`
- **Acento (Naranja Aquatour):** Un gradiente de `#fdb913` a `#f7941e`.
- **Fondo:** Blanco (`#FFFFFF`).
- **Texto:** Negro y blanco.

### Tipografía
- Se utiliza `google_fonts` con la fuente `Montserrat` para coincidir con el estilo moderno de la web.

### Componentes Personalizados
- **Botón Interactivo:** Un botón personalizado con fondo de gradiente naranja y un efecto de sombra que se intensifica al pasar el cursor por encima.

### Autenticación
- La aplicación ahora solo cuenta con una pantalla de inicio de sesión, ya que el registro de usuarios se gestionará internamente.
- Se ha implementado un botón de visibilidad en el campo de contraseña para mejorar la usabilidad.

## Arquitectura de la Aplicación

### Estructura de Navegación
```
LoginScreen
├── DashboardScreen (Admin)
│   ├── QuotesScreen
│   ├── UserManagementScreen
│   ├── ReservationsScreen
│   ├── PaymentHistoryScreen
│   ├── CompaniesScreen
│   └── ContactsScreen
└── LimitedDashboardScreen (Employee)
    ├── QuotesScreen
    ├── ReservationsScreen
    └── ContactsScreen
```

### Roles de Usuario

#### Administrador (`admin@aquatour.com`)
- Acceso completo a todos los módulos
- Gestión de usuarios
- Acceso al historial de pagos
- Administración de empresas
- Todas las funciones de empleado

#### Empleado (`employee`)
- Acceso limitado a módulos esenciales
- Gestión de cotizaciones
- Gestión de reservas
- Acceso al directorio de contactos

## Plan de Desarrollo

### Fase 1: Fundación ✅
- [x] Configuración del proyecto Flutter
- [x] Implementación del sistema de autenticación simulado
- [x] Diseño de la interfaz de usuario base
- [x] Navegación entre pantallas principales
- [x] Componentes personalizados (CustomButton)

### Fase 2: Módulos Básicos 🚧
- [ ] Implementar CRUD completo para Cotizaciones
- [ ] Desarrollar sistema de Reservas
- [ ] Crear gestión de Contactos
- [ ] Implementar administración de Empresas

### Fase 3: Funcionalidades Avanzadas 🔮
- [ ] Sistema de notificaciones
- [ ] Reportes y analytics
- [ ] Integración con APIs externas
- [ ] Base de datos persistente

### Fase 4: Optimización y Despliegue 🔮
- [ ] Optimización de rendimiento
- [ ] Testing automatizado
- [ ] Despliegue en tiendas de aplicaciones
- [ ] Documentación completa

## Especificaciones Técnicas

### Dependencias Principales
```yaml
dependencies:
  flutter: sdk
  google_fonts: ^6.3.1      # Tipografía Montserrat
  form_field_validator: ^1.1.0  # Validación de formularios
  cupertino_icons: ^1.0.8   # Iconos iOS
```

### Estructura de Archivos
```
lib/
├── main.dart                    # Configuración principal y tema
├── login_screen.dart           # Autenticación de usuarios
├── dashboard_screen.dart       # Dashboard completo (admin)
├── limited_dashboard_screen.dart # Dashboard limitado (empleado)
├── screens/                    # Pantallas de módulos
│   ├── quotes_screen.dart
│   ├── reservations_screen.dart
│   ├── contacts_screen.dart
│   ├── companies_screen.dart
│   ├── user_management_screen.dart
│   └── payment_history_screen.dart
└── widgets/                    # Componentes reutilizables
    └── custom_button.dart
```

### Tema y Estilos
```dart
// Colores corporativos
const Color colorPrimario = Color(0xFF3D1F6E);
const Color colorAcento = Color(0xFFfdb913);

// Tipografía
GoogleFonts.montserratTextTheme()

// Componentes con efectos hover y animaciones
AnimatedContainer con BoxShadow dinámico
```

## Consideraciones de Seguridad

### Autenticación Actual (Simulada)
- Credenciales hardcodeadas para desarrollo
- Validación básica de formularios
- Navegación basada en roles

### Mejoras de Seguridad Futuras
- [ ] Integración con sistema de autenticación real
- [ ] Encriptación de datos sensibles
- [ ] Tokens de sesión con expiración
- [ ] Validación del lado del servidor
- [ ] Logs de auditoría

## Experiencia de Usuario (UX)

### Principios de Diseño
1. **Simplicidad**: Interfaz limpia y fácil de navegar
2. **Consistencia**: Uso coherente de colores y tipografía corporativa
3. **Accesibilidad**: Botones grandes, contraste adecuado
4. **Retroalimentación**: Animaciones y estados visuales claros

### Flujo de Usuario
1. **Login** → Validación → Redirección basada en rol
2. **Dashboard** → Selección de módulo → Pantalla específica
3. **Navegación** → Botón de retroceso consistente
4. **Logout** → Confirmación → Retorno al login

## Próximos Pasos

### Inmediatos
1. Implementar funcionalidad real en módulo de Cotizaciones
2. Crear formularios de entrada de datos
3. Implementar almacenamiento local temporal

### Mediano Plazo
1. Integrar base de datos (SQLite local o Firebase)
2. Desarrollar API REST para sincronización
3. Implementar sistema de notificaciones

### Largo Plazo
1. Migrar a arquitectura Clean/MVVM
2. Implementar testing automatizado
3. Optimizar para múltiples plataformas (Web, Desktop)

---

**Última actualización**: Septiembre 2024  
**Versión del blueprint**: 2.0
