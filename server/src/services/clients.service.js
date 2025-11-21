import { query, getConnection } from '../config/db.js';
import { validateEmailUnique, validatePhoneUnique, validateDocumentUnique } from './email-validation.service.js';

const baseSelect = `
  SELECT
    c.id_cliente,
    c.nombres,
    c.apellidos,
    c.email,
    c.telefono,
    c.documento,
    c.nacionalidad,
    c.pasaporte,
    c.estado_civil,
    c.preferencias_viaje,
    c.satisfaccion,
    c.fecha_registro,
    c.fecha_actualizacion,
    c.id_usuario,
    c.estado_cliente,
    c.id_contacto_origen,
    c.tipo_fuente_directa,
    -- Usuario que registra
    u.nombre AS nombre_usuario,
    u.apellido AS apellido_usuario
  FROM Cliente c
  LEFT JOIN Usuario u ON c.id_usuario = u.id_usuario
`;

const mapDbClient = (row) => {
  if (!row) return null;

  return {
    id: row.id_cliente,
    id_cliente: row.id_cliente,
    nombreCompleto: `${row.nombres || ''} ${row.apellidos || ''}`.trim(),
    nombre: `${row.nombres || ''} ${row.apellidos || ''}`.trim(),
    nombres: row.nombres,
    apellidos: row.apellidos,
    email: row.email,
    telefono: row.telefono,
    documento: row.documento,
    pais: row.nacionalidad,
    nacionalidad: row.nacionalidad,
    pasaporte: row.pasaporte,
    estadoCivil: row.estado_civil,
    estado_civil: row.estado_civil,
    interes: row.preferencias_viaje || '',
    preferencias_viaje: row.preferencias_viaje,
    satisfaccion: row.satisfaccion,
    fechaRegistro: row.fecha_registro,
    fecha_registro: row.fecha_registro,
    fecha_actualizacion: row.fecha_actualizacion,
    idEmpleado: row.id_usuario,
    id_usuario: row.id_usuario,
    estado_cliente: row.estado_cliente,
    id_contacto_origen: row.id_contacto_origen,
    idContactoOrigen: row.id_contacto_origen,
    tipo_fuente_directa: row.tipo_fuente_directa,
    tipoFuenteDirecta: row.tipo_fuente_directa,
    nombre_usuario: row.nombre_usuario,
    apellido_usuario: row.apellido_usuario,
  };
};

export const findAllClients = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY c.fecha_registro DESC`);
  return rows.map(mapDbClient);
};

export const findClientById = async (idCliente) => {
  const [rows] = await query(
    `${baseSelect}
     WHERE c.id_cliente = ?
     LIMIT 1`,
    [idCliente]
  );
  return mapDbClient(rows[0]);
};

export const findClientsByUser = async (idUsuario) => {
  const [rows] = await query(
    `${baseSelect}
     WHERE c.id_usuario = ?
     ORDER BY c.fecha_registro DESC`,
    [idUsuario]
  );
  return rows.map(mapDbClient);
};

export const findClientByEmail = async (email, excludeId) => {
  const params = [email];
  let whereClause = 'c.email = ?';

  if (excludeId) {
    whereClause += ' AND c.id_cliente <> ?';
    params.push(excludeId);
  }

  const [rows] = await query(
    `${baseSelect}
     WHERE ${whereClause}
     LIMIT 1`,
    params
  );
  return mapDbClient(rows[0]);
};

export const createClient = async (clientData) => {
  // Validar documento duplicado globalmente
  if (clientData.documento) {
    await validateDocumentUnique(clientData.documento, { excludeTable: 'Cliente' });
  }

  // Validar email duplicado globalmente
  await validateEmailUnique(clientData.email, { excludeTable: 'Cliente' });

  // Validar teléfono duplicado globalmente
  if (clientData.telefono) {
    await validatePhoneUnique(clientData.telefono, { excludeTable: 'Cliente' });
  }

  const connection = await getConnection();

  try {
    // Campos requeridos que vienen del formulario de Flutter
    const requiredFields = [
      'nombres',
      'apellidos',
      'email',
      'telefono',
      'documento',
      'nacionalidad',
      'pasaporte',
      'estado_civil',
      'id_usuario'
    ];

    // Validar campos requeridos
    const missingFields = requiredFields.filter(field => !clientData[field]);
    if (missingFields.length > 0) {
      throw new Error(`Faltan campos requeridos: ${missingFields.join(', ')}`);
    }

    // Crear cliente con los campos básicos del formulario
    const [result] = await connection.execute(
      `INSERT INTO Cliente (
        nombres,
        apellidos,
        email,
        telefono,
        documento,
        nacionalidad,
        pasaporte,
        estado_civil,
        preferencias_viaje,
        satisfaccion,
        id_usuario,
        estado_cliente,
        id_contacto_origen,
        tipo_fuente_directa,
        fecha_registro,
        fecha_actualizacion
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        clientData.nombres,
        clientData.apellidos,
        clientData.email,
        clientData.telefono,
        clientData.documento,
        clientData.nacionalidad,
        clientData.pasaporte,
        clientData.estado_civil,
        clientData.preferencias_viaje || '',
        clientData.satisfaccion || 3,
        clientData.id_usuario,
        'activo',
        clientData.id_contacto_origen || null,
        clientData.tipo_fuente_directa || null,
        new Date(),
        new Date()
      ]
    );

    // Obtener el cliente recién creado
    const [createdClient] = await connection.query(
      'SELECT * FROM Cliente WHERE id_cliente = ?',
      [result.insertId]
    );

    return mapDbClient(createdClient[0]);
  } catch (error) {
    console.error('Error al crear el cliente:', error);
    throw error;
  } finally {
    connection.release();
  }
};

export const updateClient = async (idCliente, clientData) => {
  const existingClient = await findClientById(idCliente);
  if (!existingClient) return null;

  // Validar documento duplicado globalmente
  if (clientData.documento) {
    await validateDocumentUnique(clientData.documento, { 
      excludeTable: 'Cliente', 
      excludeId: idCliente 
    });
  }

  // Validar email duplicado globalmente
  if (clientData.email) {
    await validateEmailUnique(clientData.email, { 
      excludeTable: 'Cliente', 
      excludeId: idCliente 
    });
  }

  // Validar teléfono duplicado globalmente
  if (clientData.telefono) {
    await validatePhoneUnique(clientData.telefono, { 
      excludeTable: 'Cliente', 
      excludeId: idCliente 
    });
  }

  const connection = await getConnection();

  try {
    const fields = [];
    const values = [];

    // Campos básicos que pueden ser actualizados desde el formulario
    const updatableFields = [
      { column: 'nombres', key: 'nombres' },
      { column: 'apellidos', key: 'apellidos' },
      { column: 'email', key: 'email' },
      { column: 'telefono', key: 'telefono' },
      { column: 'documento', key: 'documento' },
      { column: 'nacionalidad', key: 'nacionalidad' },
      { column: 'pasaporte', key: 'pasaporte' },
      { column: 'estado_civil', key: 'estado_civil' },
      { column: 'preferencias_viaje', key: 'preferencias_viaje' },
      { column: 'satisfaccion', key: 'satisfaccion' },
      { column: 'estado_cliente', key: 'estado_cliente' },
      { column: 'id_contacto_origen', key: 'id_contacto_origen' },
      { column: 'tipo_fuente_directa', key: 'tipo_fuente_directa' },
    ];

    for (const { column, key } of updatableFields) {
      if (clientData[key] !== undefined) {
        fields.push(`${column} = ?`);
        values.push(clientData[key]);
      }
    }

    if (!fields.length) {
      return existingClient;
    }

    values.push(new Date());
    values.push(idCliente);

    await connection.execute(
      `UPDATE Cliente
      SET ${fields.join(', ')}, fecha_actualizacion = ?
      WHERE id_cliente = ?`,
      values
    );

    return await findClientById(idCliente);
  } catch (error) {
    console.error('Error actualizando cliente:', error);
    throw error;
  } finally {
    connection.release();
  }
};

export const deleteClient = async (idCliente) => {
  const client = await findClientById(idCliente);
  if (!client) return false;

  const connection = await getConnection();

  try {
    // Verificar si tiene cotizaciones asociadas
    const [cotizaciones] = await connection.execute(
      `SELECT COUNT(*) as count FROM Cotizaciones WHERE id_cliente = ?`,
      [idCliente]
    );

    if (cotizaciones[0].count > 0) {
      const error = new Error(
        `No se puede eliminar el cliente porque tiene ${cotizaciones[0].count} cotización(es) asociada(s). Primero debe eliminar o reasignar las cotizaciones.`
      );
      error.status = 409;
      throw error;
    }

    // Verificar si tiene reservas asociadas
    const [reservas] = await connection.execute(
      `SELECT COUNT(*) as count FROM Reserva WHERE id_cliente = ?`,
      [idCliente]
    );

    if (reservas[0].count > 0) {
      const error = new Error(
        `No se puede eliminar el cliente porque tiene ${reservas[0].count} reserva(s) asociada(s). Primero debe eliminar o reasignar las reservas.`
      );
      error.status = 409;
      throw error;
    }

    // Si no tiene relaciones, proceder con la eliminación
    const [result] = await connection.execute(
      `DELETE FROM Cliente WHERE id_cliente = ?`,
      [idCliente]
    );
    return result.affectedRows > 0;
  } finally {
    connection.release();
  }
};
