# 📋 Sistema de Auditoría - Aquatour CRM

## 🎯 Descripción General

El sistema de auditoría registra automáticamente todos los cambios realizados en el CRM por administradores y asesores, proporcionando trazabilidad completa de las operaciones.

## 🏗️ Arquitectura

### Componentes Principales

1. **Modelo de Datos** (`lib/models/audit_log.dart`)
   - Define la estructura de los logs de auditoría
   - Categorías: Administrador y Asesor
   - Acciones: Crear, Editar, Eliminar, Cambiar contraseña

2. **Servicio de Auditoría** (`lib/services/audit_service.dart`)
   - Métodos para registrar y consultar logs
   - Filtros por categoría, usuario, fecha, entidad

3. **Pantalla de Auditoría** (`lib/screens/audit_screen.dart`)
   - Interfaz visual para el superadministrador
   - Dos pestañas: Administradores y Asesores
   - Búsqueda y filtros por fecha

4. **Backend API** (`server/src/routes/audit.routes.js`)
   - Endpoints RESTful para gestión de logs
   - Estadísticas y reportes

## 📊 Base de Datos

### Tabla: `audit_logs`

```sql
CREATE TABLE audit_logs (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    nombre_usuario VARCHAR(255) NOT NULL,
    rol_usuario VARCHAR(50) NOT NULL,
    accion VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    entidad VARCHAR(100) NOT NULL,
    id_entidad INT,
    nombre_entidad VARCHAR(255),
    detalles TEXT,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
```

## 🔧 Cómo Integrar el Sistema de Auditoría

### 1. Importar el Servicio

```dart
import '../services/audit_service.dart';
import '../models/audit_log.dart';
import '../models/user.dart';
```

### 2. Registrar Acciones

#### Ejemplo: Crear un Cliente

```dart
Future<void> _createClient(User currentUser) async {
  try {
    // 1. Crear el cliente
    final newClient = await ClientService.createClient(clientData);
    
    // 2. Registrar en auditoría
    await AuditService.logAction(
      usuario: currentUser,
      accion: AuditAction.crearCliente,
      entidad: 'Cliente',
      idEntidad: newClient.idCliente,
      nombreEntidad: '${newClient.nombre} ${newClient.apellido}',
      detalles: {
        'telefono': newClient.telefono,
        'email': newClient.email,
        'fuente': newClient.fuente,
      },
    );
    
    // 3. Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cliente creado exitosamente')),
    );
  } catch (e) {
    // Manejar error
  }
}
```

#### Ejemplo: Editar un Usuario

```dart
Future<void> _updateUser(User currentUser, User targetUser) async {
  try {
    // 1. Actualizar el usuario
    await UserService.updateUser(targetUser);
    
    // 2. Registrar en auditoría
    await AuditService.logAction(
      usuario: currentUser,
      accion: AuditAction.editarUsuario,
      entidad: 'Usuario',
      idEntidad: targetUser.idUsuario,
      nombreEntidad: '${targetUser.nombre} ${targetUser.apellido}',
      detalles: {
        'rol': targetUser.rol.displayName,
        'email': targetUser.email,
      },
    );
  } catch (e) {
    // Manejar error
  }
}
```

#### Ejemplo: Eliminar una Cotización

```dart
Future<void> _deleteQuote(User currentUser, Quote quote) async {
  try {
    // 1. Eliminar la cotización
    await QuoteService.deleteQuote(quote.idCotizacion!);
    
    // 2. Registrar en auditoría
    await AuditService.logAction(
      usuario: currentUser,
      accion: AuditAction.eliminarCotizacion,
      entidad: 'Cotización',
      idEntidad: quote.idCotizacion,
      nombreEntidad: 'Cotización #${quote.idCotizacion}',
      detalles: {
        'cliente': quote.nombreCliente,
        'monto': quote.montoTotal.toString(),
      },
    );
  } catch (e) {
    // Manejar error
  }
}
```

#### Ejemplo: Registrar un Pago

```dart
Future<void> _registerPayment(User currentUser, Payment payment) async {
  try {
    // 1. Registrar el pago
    final newPayment = await PaymentService.createPayment(payment);
    
    // 2. Registrar en auditoría
    await AuditService.logAction(
      usuario: currentUser,
      accion: AuditAction.registrarPago,
      entidad: 'Pago',
      idEntidad: newPayment.idPago,
      nombreEntidad: 'Pago #${newPayment.numReferencia}',
      detalles: {
        'monto': newPayment.monto.toString(),
        'metodo': newPayment.metodo,
        'tipo': newPayment.tipoPago,
      },
    );
  } catch (e) {
    // Manejar error
  }
}
```

#### Ejemplo: Cambiar Contraseña

```dart
Future<void> _changePassword(User currentUser, int targetUserId) async {
  try {
    // 1. Cambiar la contraseña
    await UserService.changePassword(targetUserId, newPassword);
    
    // 2. Registrar en auditoría
    await AuditService.logAction(
      usuario: currentUser,
      accion: AuditAction.cambiarContrasena,
      entidad: 'Usuario',
      idEntidad: targetUserId,
      nombreEntidad: targetUserName,
    );
  } catch (e) {
    // Manejar error
  }
}
```

## 📝 Acciones Disponibles

### Acciones de Administradores

- `crearUsuario` - Crear un nuevo usuario
- `editarUsuario` - Modificar datos de un usuario
- `eliminarUsuario` - Eliminar un usuario
- `cambiarContrasena` - Cambiar contraseña de un usuario
- `crearPaquete` - Crear un paquete turístico
- `editarPaquete` - Modificar un paquete
- `eliminarPaquete` - Eliminar un paquete
- `crearDestino` - Crear un destino
- `editarDestino` - Modificar un destino
- `eliminarDestino` - Eliminar un destino
- `crearContacto` - Crear un contacto
- `editarContacto` - Modificar un contacto
- `eliminarContacto` - Eliminar un contacto
- `crearProveedor` - Crear un proveedor
- `editarProveedor` - Modificar un proveedor
- `eliminarProveedor` - Eliminar un proveedor

### Acciones de Asesores

- `crearCliente` - Agregar un nuevo cliente
- `editarCliente` - Modificar datos de un cliente
- `eliminarCliente` - Eliminar un cliente
- `crearCotizacion` - Crear una cotización
- `editarCotizacion` - Modificar una cotización
- `eliminarCotizacion` - Eliminar una cotización
- `crearReserva` - Crear una reserva
- `editarReserva` - Modificar una reserva
- `eliminarReserva` - Eliminar una reserva
- `registrarPago` - Registrar un pago
- `editarPago` - Modificar un pago
- `eliminarPago` - Eliminar un pago

## 🔍 Consultas Disponibles

### Obtener todos los logs

```dart
final logs = await AuditService.getAllLogs();
```

### Filtrar por categoría

```dart
final adminLogs = await AuditService.getLogsByCategory(AuditCategory.administrador);
final asesorLogs = await AuditService.getLogsByCategory(AuditCategory.asesor);
```

### Filtrar por usuario

```dart
final userLogs = await AuditService.getLogsByUser(userId);
```

### Filtrar por rango de fechas

```dart
final logs = await AuditService.getLogsByDateRange(
  DateTime(2024, 1, 1),
  DateTime(2024, 12, 31),
);
```

### Obtener estadísticas

```dart
final stats = await AuditService.getAuditStats();
print('Total de logs: ${stats['total']}');
print('Por categoría: ${stats['byCategory']}');
print('Usuarios más activos: ${stats['topUsers']}');
```

## 🎨 Interfaz de Usuario

### Acceso

- **Rol requerido:** Superadministrador
- **Ubicación:** Dashboard principal, tarjeta "Auditoría del Sistema"
- **Badge:** "Solo superadmin"

### Características

1. **Dos pestañas principales:**
   - Administradores: Muestra cambios realizados por admins
   - Asesores: Muestra cambios realizados por empleados

2. **Búsqueda en tiempo real:**
   - Por nombre de usuario
   - Por tipo de acción
   - Por entidad afectada

3. **Filtros:**
   - Rango de fechas personalizado
   - Botón para limpiar filtros

4. **Visualización:**
   - Agrupación por fecha
   - Código de colores por tipo de acción:
     - Verde: Crear
     - Naranja: Editar
     - Rojo: Eliminar
     - Azul: Otras acciones

5. **Detalles:**
   - Click en cualquier log para ver detalles completos
   - Información JSON de cambios específicos

## 🚀 Migración de Base de Datos

Para crear la tabla de auditoría en tu base de datos:

```bash
# Ejecutar la migración
mysql -u usuario -p nombre_bd < server/migrations/add_audit_logs_table.sql
```

O desde MySQL Workbench/phpMyAdmin, ejecutar el contenido del archivo `add_audit_logs_table.sql`.

## 📊 Endpoints API

### POST `/api/audit-logs`
Crear un nuevo log de auditoría

### GET `/api/audit-logs`
Obtener todos los logs (límite: 1000)

### GET `/api/audit-logs/category/:categoria`
Obtener logs por categoría (administrador/asesor)

### GET `/api/audit-logs/user/:id_usuario`
Obtener logs de un usuario específico

### GET `/api/audit-logs/date-range?start=...&end=...`
Obtener logs por rango de fechas

### GET `/api/audit-logs/stats`
Obtener estadísticas de auditoría

### DELETE `/api/audit-logs/cleanup/:days`
Eliminar logs anteriores a X días (mantenimiento)

## 🔐 Seguridad

- Solo el superadministrador puede ver los logs
- Los logs no se pueden editar ni eliminar (excepto por mantenimiento)
- Cada log incluye timestamp automático
- Relación con tabla de usuarios para integridad referencial

## 📈 Mejores Prácticas

1. **Registrar siempre después de la operación exitosa:**
   ```dart
   // ✅ Correcto
   await service.createItem();
   await AuditService.logAction(...);
   
   // ❌ Incorrecto
   await AuditService.logAction(...);
   await service.createItem(); // Puede fallar
   ```

2. **Incluir detalles relevantes:**
   - Información que ayude a entender el cambio
   - No incluir contraseñas ni datos sensibles

3. **Usar try-catch:**
   - El registro de auditoría no debe romper la operación principal
   - Si falla el log, mostrar warning pero continuar

4. **Mantener consistencia:**
   - Usar siempre el mismo formato de `nombreEntidad`
   - Ser descriptivo en los detalles

## 🛠️ Mantenimiento

### Limpieza automática de logs antiguos

Se recomienda configurar un cron job para limpiar logs antiguos:

```bash
# Eliminar logs de más de 365 días cada mes
0 0 1 * * curl -X DELETE http://localhost:8080/api/audit-logs/cleanup/365
```

## 📞 Soporte

Para dudas o problemas con el sistema de auditoría, contactar al equipo de desarrollo.

---

**Última actualización:** Noviembre 2025
**Versión:** 1.0.0
