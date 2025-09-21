# Aquatour CRM

Una aplicación Flutter para la gestión interna de empleados de Aquatour.

## Descripción

Aquatour CRM es una aplicación móvil desarrollada en Flutter que funciona como sistema de gestión de relaciones con clientes (CRM) para los empleados de la empresa Aquatour. La aplicación permite a los empleados gestionar cotizaciones, reservas, contactos, empresas y más.

## Características

### 🎨 Diseño
- **Paleta de colores corporativa**: Morado primario (#3D1F6E) y naranja acento (#fdb913)
- **Tipografía**: Montserrat usando Google Fonts
- **UI moderna**: Con gradientes, sombras y efectos hover
- **Componentes personalizados**: Botones con animaciones y efectos visuales

### 🔐 Autenticación
- Sistema de login simulado con dos tipos de usuarios:
  - **Administrador**: `admin@aquatour.com` / `password123` → Acceso completo
  - **Empleado**: `employee` / `password` → Acceso limitado

### 📊 Módulos Disponibles
- **Cotizaciones**: Gestión de presupuestos y cotizaciones
- **Reservas**: Sistema de reservas de tours
- **Contactos**: Directorio de contactos de clientes
- **Empresas**: Gestión de empresas cliente
- **Usuarios**: Administración de usuarios (solo admin)
- **Historial de Pagos**: Seguimiento de pagos (solo admin)

## Instalación

### Prerrequisitos
- Flutter SDK ^3.9.0
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android/iOS o emulador

### Pasos de instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/DaviiddG/Aquatour.git
   cd aquatour
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.3.1
  form_field_validator: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── login_screen.dart           # Pantalla de autenticación
├── dashboard_screen.dart       # Dashboard principal (admin)
├── limited_dashboard_screen.dart # Dashboard limitado (empleado)
├── quotes_screen.dart          # Módulo de cotizaciones
├── reservations_screen.dart    # Módulo de reservas
├── contacts_screen.dart        # Módulo de contactos
├── companies_screen.dart       # Módulo de empresas
├── user_management_screen.dart # Gestión de usuarios
├── payment_history_screen.dart # Historial de pagos
└── widgets/
    └── custom_button.dart      # Botón personalizado con efectos
```

## Uso

### Credenciales de Prueba

**Administrador (Acceso completo):**
- Usuario: `admin@aquatour.com`
- Contraseña: `password123`

**Empleado (Acceso limitado):**
- Usuario: `employee`
- Contraseña: `password`

### Navegación
1. Inicia la aplicación
2. Ingresa las credenciales de prueba
3. Navega por los diferentes módulos desde el dashboard
4. Cada módulo muestra una pantalla de "en desarrollo" con su respectivo diseño

## Estado del Desarrollo

### ✅ Completado
- [x] Configuración inicial del proyecto
- [x] Sistema de autenticación simulado
- [x] Dashboard principal y limitado
- [x] Navegación entre pantallas
- [x] Diseño y tema corporativo
- [x] Componentes personalizados

### 🚧 En Desarrollo
- [ ] Funcionalidad completa de cotizaciones
- [ ] Sistema de reservas
- [ ] Gestión de contactos con CRUD
- [ ] Administración de empresas
- [ ] Gestión de usuarios
- [ ] Historial de pagos

### 🔮 Futuras Mejoras
- [ ] Base de datos local/remota
- [ ] Sincronización en la nube
- [ ] Notificaciones push
- [ ] Reportes y analytics
- [ ] Modo offline

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto es propiedad de Aquatour y está destinado únicamente para uso interno.

## Contacto

Para preguntas o soporte, contacta al equipo de desarrollo de Aquatour.

---

**Versión**: 1.0.0  
**Última actualización**: Septiembre 2024
