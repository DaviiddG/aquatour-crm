-- Script para limpiar auditorías incorrectas de clientes
-- Eliminar auditorías con "Crear usuario" que deberían ser "Editar cliente" o "Crear cliente"

-- Ver auditorías actuales de clientes
SELECT 
    id_log,
    accion,
    entidad,
    nombre_entidad,
    fecha_hora,
    nombre_usuario
FROM audit_logs
WHERE entidad = 'Cliente'
ORDER BY fecha_hora DESC
LIMIT 20;

-- Eliminar auditorías incorrectas (opcional - descomentar si quieres limpiar)
-- DELETE FROM audit_logs 
-- WHERE entidad = 'Cliente' 
-- AND accion = 'Crear usuario';

-- Verificar que se eliminaron
-- SELECT COUNT(*) as total_auditorias_cliente
-- FROM audit_logs
-- WHERE entidad = 'Cliente';
