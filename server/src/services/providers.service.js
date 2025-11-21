import { query } from '../config/db.js';
import { validateEmailUnique, validatePhoneUnique } from './email-validation.service.js';

const baseSelect = `
  SELECT
    p.id_proveedor AS id,
    p.nombre,
    p.tipo_proveedor AS tipoProveedor,
    p.telefono,
    p.correo,
    p.estado
  FROM Proveedores p
`;

export const findAllProviders = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY p.nombre ASC`);
  console.log(`📦 Proveedores encontrados: ${rows.length}`);
  return rows;
};

export const findProviderById = async (idProveedor) => {
  const [rows] = await query(`${baseSelect} WHERE p.id_proveedor = ? LIMIT 1`, [idProveedor]);
  return rows[0] ?? null;
};

export const findProviderByEmail = async (correo, excludeId) => {
  const params = [correo];
  let whereClause = 'p.correo = ?';

  if (excludeId) {
    whereClause += ' AND p.id_proveedor <> ?';
    params.push(excludeId);
  }

  const [rows] = await query(
    `${baseSelect}
     WHERE ${whereClause}
     LIMIT 1`,
    params
  );
  return rows[0] ?? null;
};

export const createProvider = async (payload) => {
  console.log('📦 Payload de proveedor recibido:', JSON.stringify(payload, null, 2));
  
  const nombre = payload.nombre;
  const tipoProveedor = payload.tipoProveedor || payload.tipo_proveedor;
  const telefono = payload.telefono;
  const correo = payload.correo;
  const estado = payload.estado || 'activo';

  if (!nombre || !tipoProveedor || !telefono || !correo) {
    const error = new Error('Faltan campos obligatorios para crear el proveedor');
    error.status = 400;
    throw error;
  }

  // Validar email duplicado globalmente
  await validateEmailUnique(correo, { excludeTable: 'Proveedor' });

  // Validar teléfono duplicado globalmente
  if (telefono) {
    await validatePhoneUnique(telefono, { excludeTable: 'Proveedor' });
  }

  const [result] = await query(
    `INSERT INTO Proveedores (nombre, tipo_proveedor, telefono, correo, estado)
     VALUES (?, ?, ?, ?, ?)`,
    [nombre, tipoProveedor, telefono, correo, estado]
  );

  console.log(`✅ Proveedor creado con id=${result.insertId}`);
  return findProviderById(result.insertId);
};

export const updateProvider = async (idProveedor, payload) => {
  const nombre = payload.nombre;
  const tipoProveedor = payload.tipoProveedor || payload.tipo_proveedor;
  const telefono = payload.telefono;
  const correo = payload.correo;
  const estado = payload.estado || 'activo';

  if (!nombre || !tipoProveedor || !telefono || !correo) {
    const error = new Error('Faltan campos obligatorios para actualizar el proveedor');
    error.status = 400;
    throw error;
  }

  // Validar email duplicado globalmente
  await validateEmailUnique(correo, { 
    excludeTable: 'Proveedor', 
    excludeId: idProveedor 
  });

  // Validar teléfono duplicado globalmente
  if (telefono) {
    await validatePhoneUnique(telefono, { 
      excludeTable: 'Proveedor', 
      excludeId: idProveedor 
    });
  }

  const [result] = await query(
    `UPDATE Proveedores
     SET nombre = ?, tipo_proveedor = ?, telefono = ?, correo = ?, estado = ?
     WHERE id_proveedor = ?`,
    [nombre, tipoProveedor, telefono, correo, estado, idProveedor]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  console.log(`✅ Proveedor ${idProveedor} actualizado`);
  return findProviderById(idProveedor);
};

export const deleteProvider = async (idProveedor) => {
  const [result] = await query(`DELETE FROM Proveedores WHERE id_proveedor = ?`, [idProveedor]);
  return result.affectedRows > 0;
};
