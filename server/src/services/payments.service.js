import { query } from '../config/db.js';

const baseSelect = `
  SELECT
    p.id_pago AS id,
    p.fecha_pago AS fechaPago,
    p.metodo,
    p.banco_emisor AS bancoEmisor,
    p.num_referencia AS numReferencia,
    p.monto,
    p.id_reserva AS idReserva
  FROM Pago p
`;

export const findAllPayments = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY p.fecha_pago DESC`);
  console.log(`📋 Pagos encontrados: ${rows.length}`);
  return rows;
};

export const findPaymentById = async (idPago) => {
  const [rows] = await query(`${baseSelect} WHERE p.id_pago = ? LIMIT 1`, [idPago]);
  return rows[0] ?? null;
};

export const findPaymentsByReservation = async (idReserva) => {
  const [rows] = await query(`${baseSelect} WHERE p.id_reserva = ? ORDER BY p.fecha_pago DESC`, [idReserva]);
  console.log(`📋 Pagos de reserva ${idReserva}: ${rows.length}`);
  return rows;
};

export const findPaymentsByEmployee = async (idUsuarioOrEmpleado) => {
  console.log(`🔍 Buscando pagos para empleado id=${idUsuarioOrEmpleado}`);
  
  // Buscar id_empleado desde id_usuario
  const [empleadoRows] = await query(`SELECT id_empleado FROM Empleado WHERE id_usuario = ?`, [idUsuarioOrEmpleado]);
  
  let idEmpleado = idUsuarioOrEmpleado;
  if (empleadoRows.length > 0) {
    idEmpleado = empleadoRows[0].id_empleado;
    console.log(`✅ Convertido id_usuario=${idUsuarioOrEmpleado} a id_empleado=${idEmpleado}`);
  }
  
  const [rows] = await query(`
    ${baseSelect}
    INNER JOIN Reserva r ON p.id_reserva = r.id_reserva
    WHERE r.id_empleado = ?
    ORDER BY p.fecha_pago DESC
  `, [idEmpleado]);
  
  console.log(`📋 Pagos del empleado ${idEmpleado}: ${rows.length}`);
  return rows;
};

export const createPayment = async (payload) => {
  console.log('📦 Payload de pago recibido:', JSON.stringify(payload, null, 2));
  
  const fechaPago = payload.fechaPago || payload.fecha_pago || new Date().toISOString();
  const metodo = payload.metodo;
  const bancoEmisor = payload.bancoEmisor || payload.banco_emisor;
  const numReferencia = payload.numReferencia || payload.num_referencia;
  const monto = payload.monto;
  const idReserva = payload.idReserva || payload.id_reserva;

  if (!metodo || !numReferencia || !monto || !idReserva) {
    const error = new Error('Faltan campos obligatorios para crear el pago');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `INSERT INTO Pago (fecha_pago, metodo, banco_emisor, num_referencia, monto, id_reserva)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [fechaPago, metodo, bancoEmisor, numReferencia, monto, idReserva]
  );

  console.log(`✅ Pago creado con id=${result.insertId}`);
  return findPaymentById(result.insertId);
};

export const updatePayment = async (idPago, payload) => {
  const fechaPago = payload.fechaPago || payload.fecha_pago;
  const metodo = payload.metodo;
  const bancoEmisor = payload.bancoEmisor || payload.banco_emisor;
  const numReferencia = payload.numReferencia || payload.num_referencia;
  const monto = payload.monto;
  const idReserva = payload.idReserva || payload.id_reserva;

  if (!metodo || !numReferencia || !monto || !idReserva) {
    const error = new Error('Faltan campos obligatorios para actualizar el pago');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `UPDATE Pago
     SET fecha_pago = ?, metodo = ?, banco_emisor = ?, num_referencia = ?, monto = ?, id_reserva = ?
     WHERE id_pago = ?`,
    [fechaPago, metodo, bancoEmisor, numReferencia, monto, idReserva, idPago]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  return findPaymentById(idPago);
};

export const deletePayment = async (idPago) => {
  const [result] = await query(`DELETE FROM Pago WHERE id_pago = ?`, [idPago]);
  return result.affectedRows > 0;
};
