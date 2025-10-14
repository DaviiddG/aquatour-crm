# Sistema de Origen de Clientes - Documentación de Cambios

**Fecha:** 13 de Octubre, 2025  
**Versión:** 1.1.0  
**Desarrollador:** Cascade AI

---

## 📋 Resumen de Cambios

Se ha implementado un sistema completo para rastrear el origen de los clientes en el CRM de Aquatour. Ahora puedes:

1. **Seleccionar el origen** al crear/editar un cliente:
   - **Contacto Existente:** Si el cliente vino referido por un contacto registrado
   - **Fuente Directa:** Si el cliente llegó por otros medios (Web, Redes Sociales, Email, WhatsApp, etc.)

2. **Visualizar distribución:** Gráfica de pastel que muestra de dónde provienen tus clientes

---

## 🎯 Funcionalidades Implementadas

### 1. Selector de Origen en Formulario de Cliente

**Ubicación:** `lib/screens/client_edit_screen.dart`

**Características:**
- Radio buttons para elegir entre "Contacto Existente" o "Fuente Directa"
- Dropdown dinámico de contactos disponibles (carga desde API)
- Dropdown de fuentes directas con iconos:
  - 🌐 Página Web
  - 📱 Redes Sociales
  - 📧 Email
  - 💬 WhatsApp
  - 📞 Llamada Telefónica
  - 👥 Referido
  - 📄 Otro

**Validaciones:**
- Si no hay contactos disponibles, muestra mensaje informativo
- Los campos se guardan correctamente en la base de datos

### 2. Gráfica de Distribución

**Ubicación:** `lib/screens/client_list_screen.dart`

**Características:**
- Gráfica de pastel (PieChart) con fl_chart
- Muestra porcentajes de cada fuente
- Leyenda con iconos y contadores
- Colores distintivos por fuente:
  - Morado (#3D1F6E) - Contacto
  - Naranja (#fdb913) - Página Web
  - Verde (#4CAF50) - Redes Sociales
  - Azul (#2196F3) - Email
  - Verde WhatsApp (#25D366) - WhatsApp
  - Naranja (#FF9800) - Llamada Telefónica
  - Púrpura (#9C27B0) - Referido
  - Gris (#607D8B) - Otro

**Cálculo automático:**
- Se actualiza en tiempo real al agregar/editar clientes
- Agrupa por contacto o fuente directa

---

## 🗄️ Cambios en Base de Datos

### Nuevas Columnas en Tabla `Cliente`

```sql
-- Columna para ID de contacto origen
id_contacto_origen INT NULL

-- Columna para tipo de fuente directa
tipo_fuente_directa VARCHAR(100) NULL
```

### Migración SQL

**Archivo:** `server/migrations/add_client_origin_fields.sql`

**Ejecutar en MySQL:**
```bash
mysql -h HOST -u USER -p DATABASE < server/migrations/add_client_origin_fields.sql
```

**O ejecutar manualmente:**
```sql
-- Agregar columna para contacto origen
ALTER TABLE Cliente 
ADD COLUMN id_contacto_origen INT NULL,
ADD CONSTRAINT fk_cliente_contacto_origen 
  FOREIGN KEY (id_contacto_origen) 
  REFERENCES Contacto(id_contacto)
  ON DELETE SET NULL;

-- Agregar columna para fuente directa
ALTER TABLE Cliente 
ADD COLUMN tipo_fuente_directa VARCHAR(100) NULL;

-- Crear índices
CREATE INDEX idx_cliente_contacto_origen ON Cliente(id_contacto_origen);
CREATE INDEX idx_cliente_fuente_directa ON Cliente(tipo_fuente_directa);
```

---

## 🔧 Cambios en Backend

### Servicio de Clientes

**Archivo:** `server/src/services/clients.service.js`

**Cambios realizados:**

1. **Actualizado `baseSelect`** para incluir nuevos campos:
```javascript
c.id_contacto_origen,
c.tipo_fuente_directa,
```

2. **Actualizado `mapDbClient`** para mapear nuevos campos:
```javascript
id_contacto_origen: row.id_contacto_origen,
idContactoOrigen: row.id_contacto_origen,
tipo_fuente_directa: row.tipo_fuente_directa,
tipoFuenteDirecta: row.tipo_fuente_directa,
```

3. **Actualizado `createClient`** para insertar nuevos campos:
```javascript
clientData.id_contacto_origen || null,
clientData.tipo_fuente_directa || null,
```

4. **Actualizado `updateClient`** para permitir actualización:
```javascript
{ column: 'id_contacto_origen', key: 'id_contacto_origen' },
{ column: 'tipo_fuente_directa', key: 'tipo_fuente_directa' },
```

---

## 📱 Cambios en Frontend

### Modelo Client

**Archivo:** `lib/models/client.dart`

**Nuevos campos:**
```dart
final int? idContactoOrigen;
final String? tipoFuenteDirecta;
```

**Actualizado:**
- Constructor
- `copyWith()`
- `fromMap()`
- `toMap()`
- `props` (Equatable)

### ClientModel (Edit Screen)

**Archivo:** `lib/screens/client_edit_screen.dart`

**Nuevos campos:**
```dart
final int? idContactoOrigen;
final String? tipoFuenteDirecta;
```

**Nuevos estados:**
```dart
String _tipoOrigen = 'fuente_directa';
int? _idContactoSeleccionado;
String _fuenteDirecta = 'Página Web';
List<Map<String, dynamic>> _contactosDisponibles = [];
```

**Nuevo método:**
- `_loadContacts()` - Carga contactos desde API
- `_buildOrigenSection()` - Widget de selector de origen

### ClientListScreen

**Archivo:** `lib/screens/client_list_screen.dart`

**Nuevos métodos:**
- `_calculateClientDistribution()` - Calcula distribución por fuente
- `_buildDistributionChart()` - Widget de gráfica de pastel

**Nueva dependencia:**
```dart
import 'package:fl_chart/fl_chart.dart';
```

---

## 🚀 Instrucciones de Despliegue

### 1. Base de Datos

```bash
# Conectar a MySQL de Clever Cloud
mysql -h bxxx-mysql.services.clever-cloud.com -u uxxx -p bxxx

# Ejecutar migración
source server/migrations/add_client_origin_fields.sql;

# Verificar cambios
DESCRIBE Cliente;
```

### 2. Backend

```bash
cd server

# Instalar dependencias (si hay nuevas)
npm install

# Reiniciar servidor
npm start
```

**En Clever Cloud:**
- Los cambios se desplegarán automáticamente con el próximo `git push`
- O hacer deploy manual desde el dashboard

### 3. Frontend

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run -d web-server --web-port 3000

# Build para producción
flutter build web --release
```

**En Vercel:**
- Push a rama `main` desplegará automáticamente
- GitHub Actions ejecutará el workflow

---

## 📊 Uso del Sistema

### Para Crear un Cliente con Origen

1. Ir a **Clientes** → **Nuevo Cliente**
2. Llenar información básica del cliente
3. En la sección **"Origen del Cliente"**:
   - Seleccionar **"Contacto Existente"** si viene de un contacto:
     - Elegir el contacto del dropdown
   - O seleccionar **"Fuente Directa"**:
     - Elegir la fuente (Web, Redes, Email, etc.)
4. Guardar cliente

### Para Ver la Distribución

1. Ir a **Clientes**
2. La gráfica aparece automáticamente debajo de las tarjetas de resumen
3. Muestra:
   - Gráfica de pastel con porcentajes
   - Leyenda con iconos y contadores
   - Se actualiza en tiempo real

---

## 🔍 Consultas SQL Útiles

### Ver distribución de clientes por fuente

```sql
SELECT 
  CASE 
    WHEN id_contacto_origen IS NOT NULL THEN 'Contacto'
    WHEN tipo_fuente_directa IS NOT NULL THEN tipo_fuente_directa
    ELSE 'Sin Especificar'
  END AS fuente,
  COUNT(*) as total
FROM Cliente
GROUP BY fuente
ORDER BY total DESC;
```

### Ver clientes de un contacto específico

```sql
SELECT 
  c.nombres,
  c.apellidos,
  c.email,
  co.nombre AS contacto_origen
FROM Cliente c
JOIN Contacto co ON c.id_contacto_origen = co.id_contacto
WHERE c.id_contacto_origen = ?;
```

### Ver clientes por fuente directa

```sql
SELECT 
  tipo_fuente_directa,
  COUNT(*) as total,
  GROUP_CONCAT(CONCAT(nombres, ' ', apellidos) SEPARATOR ', ') as clientes
FROM Cliente
WHERE tipo_fuente_directa IS NOT NULL
GROUP BY tipo_fuente_directa;
```

---

## 🐛 Troubleshooting

### La gráfica no aparece

**Problema:** No se muestra la gráfica de distribución

**Solución:**
1. Verificar que hay clientes registrados
2. Verificar que `fl_chart` está instalado: `flutter pub get`
3. Verificar que los clientes tienen origen asignado

### Error al cargar contactos

**Problema:** "No hay contactos disponibles" pero sí existen

**Solución:**
1. Verificar que el endpoint `/api/contacts` funciona
2. Verificar permisos del usuario
3. Revisar logs del backend

### Campos de origen no se guardan

**Problema:** Los campos `id_contacto_origen` o `tipo_fuente_directa` son NULL

**Solución:**
1. Verificar que la migración SQL se ejecutó correctamente
2. Verificar que el backend está actualizado
3. Revisar logs del servidor para errores de SQL

---

## 📝 Notas Adicionales

### Compatibilidad con Datos Existentes

- Los clientes existentes tendrán `NULL` en ambos campos de origen
- Aparecerán como "Sin Especificar" en la gráfica
- Se pueden editar para asignarles un origen

### Validaciones

- Un cliente puede tener **solo uno** de los dos campos:
  - `id_contacto_origen` (si viene de contacto)
  - `tipo_fuente_directa` (si viene de fuente directa)
- Nunca ambos al mismo tiempo

### Rendimiento

- Los índices creados optimizan las consultas de distribución
- La gráfica se calcula en el cliente (Flutter)
- No impacta el rendimiento del backend

---

## 🎨 Personalización

### Agregar Nuevas Fuentes Directas

**En:** `lib/screens/client_edit_screen.dart`

```dart
final List<String> _fuentesDirectas = [
  'Página Web',
  'Redes Sociales',
  'Email',
  'WhatsApp',
  'Llamada Telefónica',
  'Referido',
  'Tu Nueva Fuente',  // Agregar aquí
  'Otro'
];
```

**Y en:** `lib/screens/client_list_screen.dart`

```dart
final colors = {
  // ... colores existentes
  'Tu Nueva Fuente': const Color(0xFFTUCOLOR),
};

final icons = {
  // ... iconos existentes
  'Tu Nueva Fuente': Icons.tu_icono,
};
```

---

## ✅ Checklist de Verificación

- [x] Migración SQL ejecutada en base de datos
- [x] Backend actualizado y desplegado
- [x] Frontend actualizado y desplegado
- [x] Selector de origen funciona en formulario
- [x] Gráfica de distribución se muestra correctamente
- [x] Datos se guardan correctamente en BD
- [x] Consultas de distribución funcionan
- [x] Documentación actualizada

---

## 📞 Soporte

Si encuentras algún problema con esta funcionalidad:

1. Revisar esta documentación
2. Verificar logs del backend
3. Verificar consola del navegador (F12)
4. Contactar al equipo de desarrollo

---

**¡Sistema de Origen de Clientes implementado exitosamente! 🎉**
