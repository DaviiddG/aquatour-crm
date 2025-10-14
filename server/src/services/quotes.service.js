import { query } from '../config/db.js';
import {
  findCompanionsByQuote,
  createMultipleCompanions,
  updateCompanionsByQuote,
  deleteCompanionsByQuote,
} from './companions.service.js';

const baseSelect = `
  SELECT
    c.id_cotizacion AS id,
    c.fecha_inicio_viaje AS fechaInicioViaje,
    c.fecha_fin_viaje AS fechaFinViaje,
    c.precio_estimado AS precioEstimado,
    c.id_paquete AS idPaquete,
    c.id_cliente AS idCliente,
    c.id_empleado AS idEmpleado,
    'pendiente' AS estado
  FROM Cotizaciones c
`;

export const findAllQuotes = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY c.fecha_inicio_viaje DESC`);
  console.log(`📋 Cotizaciones encontradas: ${rows.length}`);
  
  // Cargar acompañantes para cada cotización
  for (const quote of rows) {
    quote.acompanantes = await findCompanionsByQuote(quote.id);
  }
  
  return rows;
};

export const findQuotesByEmployee = async (idUsuario) => {
  // Primero obtener el id_empleado del id_usuario
  const [empleadoRows] = await query(`SELECT id_empleado FROM Empleado WHERE id_usuario = ?`, [idUsuario]);
  
  if (empleadoRows.length === 0) {
    console.log(`⚠️ No existe empleado para id_usuario=${idUsuario}`);
    return [];
  }
  
  const idEmpleado = empleadoRows[0].id_empleado;
  const [rows] = await query(`${baseSelect} WHERE c.id_empleado = ? ORDER BY c.fecha_inicio_viaje DESC`, [idEmpleado]);
  console.log(`📋 Cotizaciones del empleado ${idEmpleado} (usuario ${idUsuario}): ${rows.length}`);
  
  // Cargar acompañantes para cada cotización
  for (const quote of rows) {
    quote.acompanantes = await findCompanionsByQuote(quote.id);
  }
  
  return rows;
};

export const findQuoteById = async (idCotizacion) => {
  const [rows] = await query(`${baseSelect} WHERE c.id_cotizacion = ? LIMIT 1`, [idCotizacion]);
  const quote = rows[0] ?? null;
  
  if (quote) {
    // Cargar acompañantes
    quote.acompanantes = await findCompanionsByQuote(quote.id);
  }
  
  return quote;
};

export const createQuote = async (payload) => {
  console.log('📋 Payload de cotización recibido:', JSON.stringify(payload, null, 2));
  
  const fechaInicioViaje = payload.fechaInicioViaje || payload.fecha_inicio_viaje;
  const fechaFinViaje = payload.fechaFinViaje || payload.fecha_fin_viaje;
  const precioEstimado = payload.precioEstimado || payload.precio_estimado || 0;
  const idPaquete = payload.idPaquete || payload.id_paquete || null;
  const idCliente = payload.idCliente || payload.id_cliente;
  let idEmpleado = payload.idEmpleado || payload.id_empleado;

  if (!fechaInicioViaje || !fechaFinViaje || !idCliente || !idEmpleado) {
    const error = new Error('Faltan campos obligatorios para crear la cotización');
    error.status = 400;
    throw error;
  }

  // Buscar o crear registro de empleado para este usuario
  const [empleadoRows] = await query(`SELECT id_empleado FROM Empleado WHERE id_usuario = ?`, [idEmpleado]);
  
  if (empleadoRows.length > 0) {
    idEmpleado = empleadoRows[0].id_empleado;
    console.log(`✅ Empleado encontrado: id_empleado=${idEmpleado} para id_usuario=${payload.idEmpleado || payload.id_empleado}`);
  } else {
    // Crear registro de empleado si no existe
    console.log(`⚠️ No existe empleado para id_usuario=${idEmpleado}, creando uno...`);
    const [newEmpleado] = await query(
      `INSERT INTO Empleado (id_usuario, cargo, fecha_contratacion) VALUES (?, ?, NOW())`,
      [idEmpleado, 'Asesor']
    );
    idEmpleado = newEmpleado.insertId;
    console.log(`✅ Empleado creado: id_empleado=${idEmpleado}`);
  }

  const [result] = await query(
    `INSERT INTO Cotizaciones (fecha_inicio_viaje, fecha_fin_viaje, precio_estimado, id_paquete, id_cliente, id_empleado)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [fechaInicioViaje, fechaFinViaje, precioEstimado, idPaquete, idCliente, idEmpleado]
  );

  const idCotizacion = result.insertId;
  console.log(`✅ Cotización creada con id=${idCotizacion}`);
  
  // Crear acompañantes si existen
  const acompanantes = payload.acompanantes || [];
  if (acompanantes.length > 0) {
    console.log(`👥 Creando ${acompanantes.length} acompañantes...`);
    await createMultipleCompanions(idCotizacion, acompanantes);
  }
  
  return findQuoteById(idCotizacion);
};

export const updateQuote = async (idCotizacion, payload) => {
  const fechaInicioViaje = payload.fechaInicioViaje || payload.fecha_inicio_viaje;
  const fechaFinViaje = payload.fechaFinViaje || payload.fecha_fin_viaje;
  const precioEstimado = payload.precioEstimado || payload.precio_estimado;
  const idPaquete = payload.idPaquete || payload.id_paquete || null;
  const idCliente = payload.idCliente || payload.id_cliente;

  if (!fechaInicioViaje || !fechaFinViaje || !idCliente) {
    const error = new Error('Faltan campos obligatorios para actualizar la cotización');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `UPDATE Cotizaciones
     SET fecha_inicio_viaje = ?, fecha_fin_viaje = ?, precio_estimado = ?, id_paquete = ?, id_cliente = ?
     WHERE id_cotizacion = ?`,
    [fechaInicioViaje, fechaFinViaje, precioEstimado, idPaquete, idCliente, idCotizacion]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  console.log(`✅ Cotización ${idCotizacion} actualizada`);
  
  // Actualizar acompañantes
  const acompanantes = payload.acompanantes || [];
  console.log(`👥 Actualizando acompañantes (${acompanantes.length})...`);
  await updateCompanionsByQuote(idCotizacion, acompanantes);
  
  return findQuoteById(idCotizacion);
};

export const deleteQuote = async (idCotizacion) => {
  // Los acompañantes se eliminan automáticamente por ON DELETE CASCADE
  const [result] = await query(`DELETE FROM Cotizaciones WHERE id_cotizacion = ?`, [idCotizacion]);
  return result.affectedRows > 0;
};
