-- Script para actualizar reservas antiguas sin paquete ni destino
-- Asignar un destino por defecto a las reservas que no tienen ni paquete ni destino

-- Primero, verificar cuántas reservas no tienen paquete ni destino
SELECT COUNT(*) as reservas_sin_paquete_ni_destino
FROM Reserva
WHERE id_paquete IS NULL AND id_destino IS NULL;

-- Ver las reservas afectadas
SELECT id_reserva, fecha_inicio_viaje, fecha_fin_viaje, total_pago, id_cliente
FROM Reserva
WHERE id_paquete IS NULL AND id_destino IS NULL;

-- OPCIÓN 1: Asignar el primer destino disponible a todas las reservas sin paquete ni destino
-- (Descomenta las siguientes líneas si quieres usar esta opción)
/*
UPDATE Reserva r
SET r.id_destino = (SELECT id_destino FROM Destino LIMIT 1)
WHERE r.id_paquete IS NULL AND r.id_destino IS NULL;
*/

-- OPCIÓN 2: Dejar que el usuario asigne manualmente los destinos
-- No hacer nada automáticamente, solo mostrar las reservas que necesitan actualización

-- Verificar el resultado
SELECT 
    r.id_reserva,
    r.fecha_inicio_viaje,
    r.total_pago,
    CASE 
        WHEN r.id_paquete IS NOT NULL THEN 'Tiene paquete'
        WHEN r.id_destino IS NOT NULL THEN 'Tiene destino'
        ELSE 'Sin paquete ni destino'
    END as estado
FROM Reserva r;
