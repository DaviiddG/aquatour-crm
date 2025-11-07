-- Script para agregar el campo precio_base a la tabla destinations
-- Ejecutar este script en la base de datos MySQL de Clever Cloud

-- Agregar columna precio_base a la tabla destinations
ALTER TABLE destinations 
ADD COLUMN precio_base DECIMAL(10, 2) NULL 
COMMENT 'Precio base por persona para el destino';

-- Verificar que la columna se agregó correctamente
DESCRIBE destinations;

-- Opcional: Actualizar destinos existentes con un precio por defecto
-- Descomenta las siguientes líneas si quieres establecer un precio por defecto
-- UPDATE destinations SET precio_base = 500000 WHERE precio_base IS NULL;

-- Consulta para ver los destinos con sus precios
SELECT 
    id_destino,
    ciudad,
    pais,
    precio_base,
    descripcion
FROM destinations
ORDER BY pais, ciudad;
