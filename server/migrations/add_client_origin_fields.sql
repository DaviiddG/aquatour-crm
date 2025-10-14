-- Migración: Agregar campos de origen del cliente
-- Fecha: 2025-10-13
-- Descripción: Agrega campos para rastrear el origen de los clientes (contacto o fuente directa)

-- Agregar columna para ID de contacto origen (si el cliente vino de un contacto existente)
ALTER TABLE Cliente 
ADD COLUMN id_contacto_origen INT NULL,
ADD CONSTRAINT fk_cliente_contacto_origen 
  FOREIGN KEY (id_contacto_origen) 
  REFERENCES Contacto(id_contacto)
  ON DELETE SET NULL;

-- Agregar columna para tipo de fuente directa (si no vino de un contacto)
ALTER TABLE Cliente 
ADD COLUMN tipo_fuente_directa VARCHAR(100) NULL
COMMENT 'Tipo de fuente directa: Página Web, Redes Sociales, Email, WhatsApp, Llamada Telefónica, Referido, Otro';

-- Crear índice para mejorar consultas de distribución
CREATE INDEX idx_cliente_contacto_origen ON Cliente(id_contacto_origen);
CREATE INDEX idx_cliente_fuente_directa ON Cliente(tipo_fuente_directa);

-- Verificar que las columnas se agregaron correctamente
SELECT 
  COLUMN_NAME, 
  DATA_TYPE, 
  IS_NULLABLE, 
  COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Cliente' 
  AND COLUMN_NAME IN ('id_contacto_origen', 'tipo_fuente_directa');

SELECT 'Migración completada exitosamente' AS resultado;
