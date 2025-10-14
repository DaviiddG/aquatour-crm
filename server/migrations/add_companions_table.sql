-- Migración: Crear tabla de Acompañantes
-- Fecha: 2025-10-13
-- Descripción: Tabla para almacenar acompañantes de cotizaciones

-- Crear tabla Acompanante
CREATE TABLE IF NOT EXISTS Acompanante (
  id_acompanante INT PRIMARY KEY AUTO_INCREMENT,
  nombres VARCHAR(150) NOT NULL,
  apellidos VARCHAR(150) NOT NULL,
  documento VARCHAR(60) NULL,
  nacionalidad VARCHAR(80) NULL DEFAULT 'Perú',
  fecha_nacimiento DATE NULL,
  es_menor BOOLEAN DEFAULT FALSE,
  id_cotizacion INT NOT NULL,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  -- Relación con Cotización
  FOREIGN KEY (id_cotizacion) REFERENCES Cotizacion(id_cotizacion) ON DELETE CASCADE,
  
  -- Índice para mejorar consultas
  INDEX idx_acompanante_cotizacion (id_cotizacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verificar que la tabla se creó correctamente
SELECT 
  TABLE_NAME,
  ENGINE,
  TABLE_ROWS,
  CREATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'Acompanante';

-- Verificar columnas
SELECT 
  COLUMN_NAME,
  DATA_TYPE,
  IS_NULLABLE,
  COLUMN_DEFAULT,
  COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'Acompanante'
ORDER BY ORDINAL_POSITION;

SELECT 'Migración completada: Tabla Acompanante creada exitosamente' AS resultado;
