# 📍 Documentación: Precio Base en Destinos

## 🎯 Objetivo

Agregar la funcionalidad de precio base a los destinos para que los administradores puedan establecer precios estándar que se utilizarán automáticamente en reservas y cotizaciones.

---

## 🔄 Cambios Implementados

### 1. **Modelo de Datos**

#### **Destination Model** (`lib/models/destination.dart`)
- ✅ Agregado campo `precioBase` (double?)
- ✅ Actualizado `copyWith()` para incluir precioBase
- ✅ Actualizado `fromMap()` y `toMap()` para serialización
- ✅ Agregado método `_parseDouble()` para conversión segura

```dart
final double? precioBase;
```

#### **Reservation Model** (`lib/models/reservation.dart`)
- ✅ Agregado campo `idDestino` (int?)
- ✅ Agregado campo `precioDestino` (double?)
- ✅ Actualizado `copyWith()`, `fromMap()` y `toMap()`

```dart
final int? idDestino;
final double? precioDestino;
```

---

### 2. **Interfaz de Usuario**

#### **Formulario de Destinos** (`lib/screens/destination_edit_screen.dart`)
- ✅ Agregado campo "Precio Base por Persona" (obligatorio)
- ✅ Validación de precio requerido
- ✅ Solo números permitidos
- ✅ Icono de pagos para identificación visual

**Ubicación:** Sección "Detalles del Destino"

#### **Formulario de Reservas** (`lib/screens/reservation_edit_screen.dart`)
- ✅ Agregado selector de tipo: "Paquete Turístico" vs "Destino Personalizado"
- ✅ Dropdown de destinos con precio visible
- ✅ Campo de precio editable (se auto-completa con precio base del destino)
- ✅ Cálculo automático del total según cantidad de personas
- ✅ Validaciones para ambos tipos de reserva

**Características:**
- Radio buttons para seleccionar tipo
- Precio se muestra en el dropdown: "Cartagena, Colombia - $500,000"
- Precio se auto-completa al seleccionar destino
- Total se calcula automáticamente: `precio × cantidad de personas`

---

### 3. **Base de Datos**

#### **Script SQL** (`server/add-precio-destinos.sql`)

```sql
ALTER TABLE destinations 
ADD COLUMN precio_base DECIMAL(10, 2) NULL 
COMMENT 'Precio base por persona para el destino';
```

**Instrucciones de Ejecución:**

1. **Conectarse a MySQL en Clever Cloud:**
   ```bash
   mysql -h bxxx-mysql.services.clever-cloud.com \
         -u uxxx \
         -p \
         bxxx
   ```

2. **Ejecutar el script:**
   ```bash
   source /ruta/al/archivo/add-precio-destinos.sql
   ```

   O copiar y pegar el contenido directamente en el cliente MySQL.

3. **Verificar:**
   ```sql
   DESCRIBE destinations;
   SELECT * FROM destinations;
   ```

---

## 📋 Flujo de Trabajo

### **Para Administradores:**

1. **Crear/Editar Destino:**
   - Ir a "Destinos"
   - Clic en "Nuevo Destino" o editar uno existente
   - Completar información básica (país, ciudad, descripción)
   - **IMPORTANTE:** Ingresar "Precio Base por Persona"
   - Guardar

2. **El precio queda almacenado** y estará disponible para:
   - Reservas con destino personalizado
   - Cotizaciones
   - Facturas

### **Para Empleados (Reservas):**

1. **Crear Nueva Reserva:**
   - Seleccionar cliente
   - **Elegir tipo:** "Paquete Turístico" o "Destino Personalizado"
   
2. **Si elige "Destino Personalizado":**
   - Seleccionar destino del dropdown
   - El precio se auto-completa con el precio base
   - Puede modificar el precio si es necesario
   - Ingresar cantidad de personas
   - El total se calcula automáticamente

3. **Si elige "Paquete Turístico":**
   - Seleccionar paquete
   - El precio se calcula según el paquete

---

## 🔍 Validaciones

### **Destinos:**
- ✅ Precio base es **obligatorio**
- ✅ Solo números permitidos
- ✅ Debe ser mayor a 0

### **Reservas:**
- ✅ Si es paquete → debe seleccionar un paquete
- ✅ Si es destino → debe seleccionar destino Y precio
- ✅ Precio por persona es obligatorio para destinos
- ✅ Total se calcula automáticamente

---

## 📊 Estructura de Datos

### **Tabla `destinations`**

| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| id_destino | INT | NO | ID único |
| ciudad | VARCHAR(100) | NO | Ciudad |
| pais | VARCHAR(100) | NO | País |
| descripcion | TEXT | SÍ | Descripción |
| clima_promedio | VARCHAR(100) | SÍ | Clima |
| temporada_alta | VARCHAR(100) | SÍ | Temporada alta |
| idioma_principal | VARCHAR(50) | SÍ | Idioma |
| moneda | VARCHAR(10) | SÍ | Moneda |
| **precio_base** | **DECIMAL(10,2)** | **SÍ** | **Precio base** |
| id_proveedor | INT | SÍ | Proveedor |

### **Tabla `reservations`**

| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| ... | ... | ... | ... |
| id_paquete | INT | SÍ | ID del paquete (si aplica) |
| **id_destino** | **INT** | **SÍ** | **ID del destino (si aplica)** |
| **precio_destino** | **DECIMAL(10,2)** | **SÍ** | **Precio del destino** |
| ... | ... | ... | ... |

---

## 🎨 Interfaz Visual

### **Formulario de Destinos:**
```
┌─────────────────────────────────────┐
│ Detalles del Destino                │
├─────────────────────────────────────┤
│ Clima Promedio                      │
│ [Tropical, 25-30°C]                 │
│                                     │
│ Temporada Alta                      │
│ [Diciembre - Marzo]                 │
│                                     │
│ Idioma Principal                    │
│ [Español]                           │
│                                     │
│ Moneda                              │
│ [COP]                               │
│                                     │
│ 💰 Precio Base por Persona *        │
│ [500000]                            │
└─────────────────────────────────────┘
```

### **Formulario de Reservas:**
```
┌─────────────────────────────────────┐
│ Tipo de Reserva                     │
├─────────────────────────────────────┤
│ ⚪ Paquete Turístico                │
│ ⚫ Destino Personalizado            │
│                                     │
│ 📍 Seleccionar destino *            │
│ [Cartagena, Colombia - $500,000]    │
│                                     │
│ 💰 Precio por persona *             │
│ [500000]                            │
│                                     │
│ ℹ️ El precio total se calculará     │
│    automáticamente según la         │
│    cantidad de personas             │
└─────────────────────────────────────┘
```

---

## ✅ Checklist de Implementación

### **Backend:**
- [x] Agregar columna `precio_base` a tabla `destinations`
- [ ] Ejecutar script SQL en Clever Cloud
- [ ] Verificar que la columna existe

### **Frontend:**
- [x] Actualizar modelo `Destination` con `precioBase`
- [x] Actualizar modelo `Reservation` con `idDestino` y `precioDestino`
- [x] Agregar campo precio en formulario de destinos
- [x] Agregar selector de tipo en formulario de reservas
- [x] Implementar cálculo automático de precio
- [x] Agregar validaciones

### **Pruebas:**
- [ ] Crear destino con precio
- [ ] Editar destino existente y agregar precio
- [ ] Crear reserva con paquete turístico
- [ ] Crear reserva con destino personalizado
- [ ] Verificar cálculo automático del total
- [ ] Verificar que se guarda correctamente en BD

---

## 🚀 Despliegue

### **1. Base de Datos:**
```bash
# Conectar a Clever Cloud
mysql -h bxxx-mysql.services.clever-cloud.com -u uxxx -p bxxx

# Ejecutar script
source add-precio-destinos.sql

# O copiar y pegar:
ALTER TABLE destinations ADD COLUMN precio_base DECIMAL(10, 2) NULL;
```

### **2. Frontend:**
```bash
# Hacer commit
git add .
git commit -m "Agregar precio base a destinos y soporte en reservas"
git push origin main

# Vercel desplegará automáticamente
```

---

## 📝 Notas Importantes

1. **Precio Base vs Precio Final:**
   - `precio_base` en destinos es el precio sugerido
   - `precio_destino` en reservas es el precio real usado
   - El empleado puede modificar el precio al crear la reserva

2. **Compatibilidad:**
   - Destinos sin precio: Se puede crear reserva pero hay que ingresar precio manualmente
   - Reservas antiguas: Funcionan normalmente (solo tienen `id_paquete`)
   - Nuevas reservas: Pueden tener `id_paquete` O `id_destino` (no ambos)

3. **Permisos:**
   - Solo **administradores** pueden crear/editar destinos
   - **Empleados** pueden crear reservas con destinos existentes
   - El precio se puede modificar al crear la reserva

---

## 🔧 Solución de Problemas

### **Error: "El precio es obligatorio"**
- **Causa:** No se ingresó precio en el formulario de destinos
- **Solución:** Ingresar un precio válido (solo números)

### **Error: "Selecciona un destino"**
- **Causa:** Se eligió "Destino Personalizado" pero no se seleccionó destino
- **Solución:** Seleccionar un destino del dropdown

### **El precio no se auto-completa**
- **Causa:** El destino no tiene precio base configurado
- **Solución:** Editar el destino y agregar precio base

### **El total no se calcula**
- **Causa:** Falta cantidad de personas o precio
- **Solución:** Verificar que ambos campos estén completos

---

## 📞 Soporte

Si tienes problemas:
1. Verificar que el script SQL se ejecutó correctamente
2. Verificar que los destinos tienen precio base
3. Revisar la consola del navegador para errores
4. Verificar que Vercel desplegó la última versión

---

**Última actualización:** 7 de noviembre de 2025
