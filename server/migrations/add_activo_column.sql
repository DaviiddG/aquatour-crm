-- Agregar columna 'activo' a la tabla Usuario
-- Esta columna indica si el usuario está activo o inactivo en el sistema

ALTER TABLE Usuario 
ADD COLUMN activo TINYINT(1) NOT NULL DEFAULT 1 
COMMENT 'Indica si el usuario está activo (1) o inactivo (0)';

-- Actualizar todos los usuarios existentes a activo por defecto
UPDATE Usuario SET activo = 1 WHERE activo IS NULL;

-- Crear índice para mejorar consultas por estado
CREATE INDEX idx_usuario_activo ON Usuario(activo);
