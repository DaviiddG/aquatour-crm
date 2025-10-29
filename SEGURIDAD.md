# 🔒 Documento de Seguridad - Aquatour CRM

## ✅ Funcionalidades de Seguridad Implementadas

### **1. Límite de Intentos de Login** ✅
**Ubicación:** `lib/login_screen.dart`

**Implementación:**
- ✅ Máximo 5 intentos de login fallidos
- ✅ Bloqueo temporal de 15 minutos después de 5 intentos
- ✅ Contador de intentos restantes
- ✅ Mensaje claro al usuario sobre el bloqueo
- ✅ Reseteo automático después de login exitoso

**Código:**
```dart
// Control de intentos
static const int _maxLoginAttempts = 5;
static const Duration _lockoutDuration = Duration(minutes: 15);
int _failedAttempts = 0;
DateTime? _lockoutUntil;
```

---

### **2. Rate Limiting en API** ✅
**Ubicación:** `server/src/middleware/rateLimiter.js`

**Implementación:**
- ✅ **Login:** 5 intentos por 15 minutos por IP
- ✅ **API General:** 100 peticiones por minuto por IP
- ✅ **Creación de recursos:** 20 creaciones por minuto por IP
- ✅ Limpieza automática de registros antiguos
- ✅ Logging de intentos sospechosos

**Endpoints Protegidos:**
```javascript
// Login
router.post('/login', loginRateLimiter(5, 15 * 60 * 1000), login);

// Uso general
app.use(rateLimiter(100, 60000));

// Creación de recursos
router.post('/users', createResourceLimiter(20, 60000), createUser);
```

---

### **3. Política de Contraseñas Fuertes** ✅
**Ubicación:** `lib/utils/password_validator.dart`

**Requisitos:**
- ✅ Mínimo 8 caracteres
- ✅ Al menos 1 letra mayúscula
- ✅ Al menos 1 letra minúscula
- ✅ Al menos 1 número
- ✅ Al menos 1 carácter especial (!@#$%^&*(),.?":{}|<>)

**Aplicación:**
- ✅ **Obligatoria** al crear usuarios nuevos
- ✅ **Opcional pero validada** al editar usuarios existentes
- ✅ **NO aplica** al iniciar sesión (para no bloquear usuarios con contraseñas antiguas)

**Código:**
```dart
// Usuario nuevo - contraseña REQUERIDA y fuerte
if (widget.user.idUsuario == null) {
  return PasswordValidator.validate(value, isRequired: true);
}
// Edición - contraseña OPCIONAL pero si se ingresa debe ser fuerte
if (value != null && value.isNotEmpty) {
  return PasswordValidator.validate(value, isRequired: false);
}
```

---

### **4. Protección SQL Injection** ✅
**Ubicación:** `server/src/services/*.service.js`

**Implementación:**
- ✅ **Prepared Statements** en todas las queries
- ✅ Parámetros escapados automáticamente por `mysql2`
- ✅ No se concatenan strings en queries SQL

**Ejemplo:**
```javascript
// ✅ CORRECTO - Prepared Statement
const [rows] = await query(
  'SELECT * FROM Usuario WHERE correo = ? AND activo = ?',
  [email, true]
);

// ❌ INCORRECTO - Vulnerable a SQL Injection
const [rows] = await query(
  `SELECT * FROM Usuario WHERE correo = '${email}' AND activo = true`
);
```

---

### **5. Logging de Acciones Críticas** ✅
**Ubicación:** `server/src/controllers/auth.controller.js`

**Eventos Registrados:**
- ✅ Login exitoso (email, rol, IP)
- ✅ Login fallido (email, IP, razón)
- ✅ Usuario inactivo intentando login
- ✅ Email inexistente
- ✅ Contraseña incorrecta
- ✅ Rate limit excedido

**Formato de Logs:**
```
✅ Login exitoso: user@example.com (administrador) desde IP: 192.168.1.1
⚠️ Intento de login con contraseña incorrecta: user@example.com desde IP: 192.168.1.1
🚫 Intentos de login excedidos para IP: 192.168.1.1 (6 intentos)
```

---

### **6. Sesión Única por Usuario** ✅
**Ubicación:** `lib/services/storage_service.dart`, `lib/main.dart`

**Implementación:**
- ✅ SessionId único por pestaña (sessionStorage)
- ✅ Detección de nueva pestaña (sin sessionId)
- ✅ Cierre automático de sesión anterior
- ✅ Verificación periódica cada 2 segundos
- ✅ Mensaje al usuario sobre cierre de sesión

**Flujo:**
1. Usuario inicia sesión → Genera sessionId único
2. Usuario abre nueva pestaña → No tiene sessionId → Pide login
3. Usuario inicia sesión en nueva pestaña → Nuevo sessionId
4. Pestaña original detecta cambio → Cierra sesión automáticamente

---

### **7. Validación en Backend** ✅
**Ubicación:** `server/src/services/users.service.js`

**Validaciones:**
- ✅ Email único (no duplicados)
- ✅ Documento único (no duplicados)
- ✅ Teléfono único (no duplicados)
- ✅ Formato de email válido
- ✅ Campos requeridos

---

## ⚠️ Funcionalidades Pendientes (Recomendadas)

### **Alta Prioridad:**
- ❌ **HTTPS Obligatorio** (configurar en producción)
- ❌ **Autenticación de dos factores (2FA)**
- ❌ **Recuperación segura de contraseña** (token por email)
- ❌ **Encriptación de datos sensibles en BD**
- ❌ **Tokens JWT con expiración** (actualmente sin expiración)

### **Media Prioridad:**
- ❌ **Protección CSRF** (Cross-Site Request Forgery)
- ❌ **Protección XSS** (sanitización de inputs)
- ❌ **Auditoría completa de cambios** (quién, qué, cuándo)
- ❌ **Alertas de seguridad** (email/SMS para actividad sospechosa)
- ❌ **Expiración de contraseñas** (cambio obligatorio cada 90 días)

### **Baja Prioridad:**
- ❌ **Dashboard de seguridad** (métricas y alertas)
- ❌ **Análisis de vulnerabilidades** (escaneo periódico)
- ❌ **Cumplimiento GDPR/CCPA**

---

## 🔐 Mejores Prácticas Implementadas

### **Contraseñas:**
- ✅ Hasheadas con bcrypt (backend)
- ✅ Nunca se almacenan en texto plano
- ✅ No se envían en respuestas de API
- ✅ Política de contraseñas fuertes

### **Sesiones:**
- ✅ Timeout por inactividad (10 minutos)
- ✅ Sesión única por usuario
- ✅ Verificación periódica de validez
- ✅ Cierre automático en pestañas inactivas

### **API:**
- ✅ Rate limiting por IP
- ✅ Prepared statements (SQL Injection)
- ✅ Logging de actividad sospechosa
- ✅ Validación de permisos por rol

### **Frontend:**
- ✅ Validación de inputs
- ✅ Límite de intentos de login
- ✅ Mensajes de error genéricos (no revelar información)
- ✅ Timeout de sesión

---

## 📊 Métricas de Seguridad

### **Protección contra Ataques:**
- ✅ **SQL Injection:** Protegido (prepared statements)
- ✅ **Fuerza Bruta:** Protegido (rate limiting + bloqueo temporal)
- ✅ **DDoS:** Parcialmente protegido (rate limiting general)
- ⚠️ **XSS:** Parcialmente protegido (validación básica)
- ⚠️ **CSRF:** No protegido (pendiente)

### **Nivel de Seguridad Actual:**
- **Autenticación:** ⭐⭐⭐⭐☆ (4/5)
- **Autorización:** ⭐⭐⭐☆☆ (3/5)
- **Datos:** ⭐⭐⭐☆☆ (3/5)
- **Red:** ⭐⭐☆☆☆ (2/5)
- **Auditoría:** ⭐⭐⭐☆☆ (3/5)

**Nivel General:** ⭐⭐⭐☆☆ (3/5) - **Bueno, pero mejorable**

---

## 🚀 Próximos Pasos Recomendados

1. **Implementar HTTPS** en producción (certificado SSL/TLS)
2. **Agregar JWT tokens** con expiración (15-30 minutos)
3. **Implementar 2FA** (código por email)
4. **Encriptar datos sensibles** en base de datos
5. **Configurar CORS** correctamente
6. **Agregar protección CSRF**
7. **Implementar recuperación de contraseña**
8. **Dashboard de seguridad** para administradores

---

## 📝 Notas Importantes

### **Para Desarrolladores:**
- Siempre usar prepared statements en queries SQL
- Nunca hardcodear credenciales en el código
- Validar TODOS los inputs en backend (nunca confiar en frontend)
- Loggear todas las acciones críticas
- Mantener dependencias actualizadas

### **Para Administradores:**
- Revisar logs regularmente
- Monitorear intentos de login fallidos
- Cambiar contraseñas periódicamente
- Mantener usuarios inactivos deshabilitados
- Hacer backups regulares de la base de datos

### **Para Usuarios:**
- Usar contraseñas fuertes y únicas
- No compartir credenciales
- Cerrar sesión al terminar
- Reportar actividad sospechosa
- Mantener navegador actualizado

---

## 📞 Contacto de Seguridad

Para reportar vulnerabilidades o problemas de seguridad:
- **Email:** security@aquatour.com
- **Prioridad:** Alta
- **Respuesta:** 24-48 horas

---

**Última actualización:** 28 de Octubre, 2025  
**Versión:** 1.0  
**Responsable:** Equipo de Desarrollo Aquatour CRM
