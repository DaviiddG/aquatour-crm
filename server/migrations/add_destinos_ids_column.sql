-- Agregar columna destinos_ids a la tabla Paquete_Turismo
-- Esta columna almacenará los IDs de destinos separados por comas (ej: "1,3,5")

ALTER TABLE Paquete_Turismo 
ADD COLUMN destinos_ids VARCHAR(255) NULL;

-- Migrar datos existentes de id_destino a destinos_ids (si existe la columna id_destino)
UPDATE Paquete_Turismo 
SET destinos_ids = CAST(id_destino AS CHAR)
WHERE id_destino IS NOT NULL;

-- Opcional: Eliminar la columna antigua id_destino si ya no se necesita
-- ALTER TABLE Paquete_Turismo DROP COLUMN id_destino;

SELECT 'Columna destinos_ids agregada exitosamente' AS resultado;
