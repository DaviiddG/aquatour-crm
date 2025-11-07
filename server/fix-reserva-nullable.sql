-- Script para permitir NULL en id_paquete de la tabla Reserva
-- Esto permite crear reservas con destino personalizado sin paquete

-- Modificar la columna id_paquete para permitir NULL
ALTER TABLE Reserva 
MODIFY COLUMN id_paquete INT NULL;

-- Verificar la estructura
DESCRIBE Reserva;

-- Ver reservas existentes
SELECT 
    id_reserva,
    cantidad_personas,
    precio_total,
    id_paquete,
    id_destino,
    precio_destino
FROM Reserva
ORDER BY id_reserva DESC
LIMIT 10;
