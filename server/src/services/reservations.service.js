import { query } from '../config/db.js';

// Helper para convertir fechas ISO a formato MySQL
const formatDateForMySQL = (isoDate) => {
  if (!isoDate) return null;
  const date = new Date(isoDate);
  return date.toISOString().slice(0, 19).replace('T', ' ');
};

const baseSelect = `
  SELECT
    r.id_reserva AS id,
    r.fecha_reserva AS fechaReserva,
    'pendiente' AS estado,
    r.cantidad_personas AS cantidadPersonas,
    r.precio_total AS totalPago,
    r.fecha_inicio_viaje AS fechaInicioViaje,
    r.fecha_fin_viaje AS fechaFinViaje,
    r.id_cliente AS idCliente,
    r.id_paquete AS idPaquete,
    r.id_destino AS idDestino,
    r.precio_destino AS precioDestino,
    r.id_empleado AS idEmpleado,
    u.nombre AS empleadoNombre,
    u.apellido AS empleadoApellido,
    CAST(COALESCE((
      SELECT SUM(p.monto)
      FROM Pago p
      WHERE p.id_reserva = r.id_reserva
    ), 0) AS DECIMAL(10,2)) AS totalPagado
  FROM Reserva r
  LEFT JOIN Empleado e ON r.id_empleado = e.id_empleado
  LEFT JOIN Usuario u ON e.id_usuario = u.id_usuario
`;

export const findAllReservations = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY r.id_reserva DESC`);
  console.log(`📋 Reservas encontradas: ${rows.length}`);
  if (rows.length > 0) {
    console.log(`📦 Primera reserva con totalPagado:`, rows[0]);
  }
  return rows;
};

export const findReservationById = async (idReserva) => {
  const [rows] = await query(`${baseSelect} WHERE r.id_reserva = ? LIMIT 1`, [idReserva]);
  return rows[0] ?? null;
};

export const findReservationsByEmployee = async (idUsuarioOrEmpleado) => {
  console.log(`🔍 Buscando reservas para id=${idUsuarioOrEmpleado}`);
  
  // Primero intentar buscar el id_empleado desde id_usuario
  const [empleadoRows] = await query(`SELECT id_empleado FROM Empleado WHERE id_usuario = ?`, [idUsuarioOrEmpleado]);
  
  let idEmpleado = idUsuarioOrEmpleado;
  if (empleadoRows.length > 0) {
    idEmpleado = empleadoRows[0].id_empleado;
    console.log(`✅ Convertido id_usuario=${idUsuarioOrEmpleado} a id_empleado=${idEmpleado}`);
  }
  
  const [rows] = await query(`${baseSelect} WHERE r.id_empleado = ? ORDER BY r.id_reserva DESC`, [idEmpleado]);
  console.log(`📋 Reservas del empleado ${idEmpleado}: ${rows.length}`);
  return rows;
};

export const createReservation = async (payload) => {
  console.log('📦 Payload recibido:', JSON.stringify(payload, null, 2));
  
  const cantidadPersonas = payload.cantidadPersonas || payload.cantidad_personas;
  const totalPago = payload.totalPago || payload.total_pago || payload.precio_total;
  const fechaInicioViaje = payload.fechaInicioViaje || payload.fecha_inicio_viaje;
  const fechaFinViaje = payload.fechaFinViaje || payload.fecha_fin_viaje;
  const idCliente = payload.idCliente || payload.id_cliente;
  let idPaquete = payload.idPaquete || payload.id_paquete;
  const idDestino = payload.idDestino || payload.id_destino;
  const precioDestino = payload.precioDestino || payload.precio_destino;
  const idEmpleado = payload.idEmpleado || payload.id_empleado;

  console.log('🔍 Valores extraídos:', {
    cantidadPersonas,
    totalPago,
    fechaInicioViaje,
    fechaFinViaje,
    idCliente,
    idPaquete,
    idDestino,
    precioDestino,
    idEmpleado,
  });

  if (!cantidadPersonas || !totalPago || !fechaInicioViaje || !fechaFinViaje || !idCliente || !idEmpleado) {
    console.error('❌ Faltan campos:', {
      cantidadPersonas: !!cantidadPersonas,
      totalPago: !!totalPago,
      fechaInicioViaje: !!fechaInicioViaje,
      fechaFinViaje: !!fechaFinViaje,
      idCliente: !!idCliente,
      idEmpleado: !!idEmpleado,
    });
    const error = new Error('Faltan campos obligatorios para crear la reserva');
    error.status = 400;
    throw error;
  }

  // Buscar o crear registro de empleado para este usuario
  let empleadoId = idEmpleado;
  const [empleadoRows] = await query(`SELECT id_empleado FROM Empleado WHERE id_usuario = ?`, [idEmpleado]);
  
  if (empleadoRows.length > 0) {
    empleadoId = empleadoRows[0].id_empleado;
    console.log(`✅ Empleado encontrado: id_empleado=${empleadoId} para id_usuario=${idEmpleado}`);
  } else {
    // Crear registro de empleado si no existe
    console.log(`⚠️ No existe empleado para id_usuario=${idEmpleado}, creando uno...`);
    const [newEmpleado] = await query(
      `INSERT INTO Empleado (id_usuario, cargo, fecha_contratacion) VALUES (?, ?, NOW())`,
      [idEmpleado, 'Asesor']
    );
    empleadoId = newEmpleado.insertId;
    console.log(`✅ Empleado creado: id_empleado=${empleadoId}`);
  }

  // No forzar paquete si hay destino personalizado
  // Solo se requiere uno de los dos: idPaquete O idDestino
  
  const [result] = await query(
    `INSERT INTO Reserva (cantidad_personas, precio_total, fecha_inicio_viaje, fecha_fin_viaje, id_cliente, id_paquete, id_destino, precio_destino, id_empleado)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      cantidadPersonas, 
      totalPago, 
      formatDateForMySQL(fechaInicioViaje), 
      formatDateForMySQL(fechaFinViaje), 
      idCliente, 
      idPaquete || null, 
      idDestino || null, 
      precioDestino || null, 
      empleadoId
    ]
  );

  console.log(`✅ Reserva creada con id_empleado=${empleadoId}`);

  return findReservationById(result.insertId);
};

export const updateReservation = async (idReserva, payload) => {
  console.log('📦 Payload recibido para actualizar:', JSON.stringify(payload, null, 2));
  
  const cantidadPersonas = payload.cantidadPersonas || payload.cantidad_personas;
  const totalPago = payload.totalPago || payload.total_pago || payload.precio_total;
  const fechaInicioViaje = payload.fechaInicioViaje || payload.fecha_inicio_viaje;
  const fechaFinViaje = payload.fechaFinViaje || payload.fecha_fin_viaje;
  const idCliente = payload.idCliente || payload.id_cliente;
  const idPaquete = payload.idPaquete || payload.id_paquete;
  const idDestino = payload.idDestino || payload.id_destino;
  const precioDestino = payload.precioDestino || payload.precio_destino;

  console.log('🔍 Valores extraídos:', {
    cantidadPersonas,
    totalPago,
    fechaInicioViaje,
    fechaFinViaje,
    idCliente,
    idPaquete,
    idDestino,
    precioDestino,
  });

  // Validar campos obligatorios (permitir 0 en totalPago)
  if (!cantidadPersonas || totalPago === undefined || totalPago === null || !fechaInicioViaje || !fechaFinViaje || !idCliente) {
    console.error('❌ Faltan campos:', {
      cantidadPersonas: !!cantidadPersonas,
      totalPago: totalPago !== undefined && totalPago !== null,
      fechaInicioViaje: !!fechaInicioViaje,
      fechaFinViaje: !!fechaFinViaje,
      idCliente: !!idCliente,
    });
    const error = new Error('Faltan campos obligatorios para actualizar la reserva');
    error.status = 400;
    throw error;
  }

  // NO actualizamos id_empleado para evitar problemas con pagos asociados
  const [result] = await query(
    `UPDATE Reserva
     SET cantidad_personas = ?, precio_total = ?, fecha_inicio_viaje = ?, fecha_fin_viaje = ?, id_cliente = ?, id_paquete = ?, id_destino = ?, precio_destino = ?
     WHERE id_reserva = ?`,
    [
      cantidadPersonas, 
      totalPago, 
      formatDateForMySQL(fechaInicioViaje), 
      formatDateForMySQL(fechaFinViaje), 
      idCliente, 
      idPaquete || null, 
      idDestino || null, 
      precioDestino || null, 
      idReserva
    ]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  console.log(`✅ Reserva ${idReserva} actualizada (id_empleado no se modifica)`);
  return findReservationById(idReserva);
};

export const deleteReservation = async (idReserva) => {
  try {
    // Verificar si hay pagos asociados a esta reserva
    const [pagos] = await query(
      `SELECT COUNT(*) as count FROM Pago WHERE id_reserva = ?`,
      [idReserva]
    );
    
    if (pagos[0].count > 0) {
      const error = new Error(`No se puede eliminar la reserva porque tiene ${pagos[0].count} pago(s) asociado(s). Elimina primero los pagos.`);
      error.status = 409; // Conflict
      throw error;
    }
    
    // Si no hay dependencias, eliminar la reserva
    const [result] = await query(`DELETE FROM Reserva WHERE id_reserva = ?`, [idReserva]);
    
    if (result.affectedRows === 0) {
      const error = new Error('Reserva no encontrada');
      error.status = 404;
      throw error;
    }
    
    console.log(`✅ Reserva ${idReserva} eliminada exitosamente`);
    return true;
  } catch (error) {
    console.error(`❌ Error eliminando reserva ${idReserva}:`, error.message);
    throw error;
  }
};
