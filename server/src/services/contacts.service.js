import { query } from '../config/db.js';

const baseSelect = `
  SELECT
    id_contacto AS id,
    nombre AS name,
    email,
    telefono AS phone,
    empresa AS company,
    creado_en AS created_at,
    actualizado_en AS updated_at
  FROM Contacto
`;

export const findAllContacts = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY creado_en DESC`);
  return rows;
};

export const findContactById = async (idContacto) => {
  const [rows] = await query(`${baseSelect} WHERE id_contacto = ? LIMIT 1`, [idContacto]);
  return rows[0] ?? null;
};

const normalizePayload = (payload = {}) => {
  return {
    nombre: payload.nombre ?? payload.name,
    email: payload.email,
    telefono: payload.telefono ?? payload.phone,
    empresa: payload.empresa ?? payload.company,
  };
};

const validateContactPayload = (payload) => {
  const requiredFields = ['nombre', 'email', 'telefono', 'empresa'];
  const missing = requiredFields.filter((field) => {
    const value = payload?.[field];
    return value == null || String(value).trim().length === 0;
  });
  if (missing.length > 0) {
    const error = new Error(`Los siguientes campos son obligatorios: ${missing.join(', ')}`);
    error.status = 400;
    throw error;
  }
};

export const createContact = async (payload) => {
  const normalized = normalizePayload(payload);
  validateContactPayload(normalized);
  const { nombre, email, telefono, empresa } = normalized;
  const [result] = await query(
    `INSERT INTO Contacto (nombre, email, telefono, empresa)
     VALUES (?, ?, ?, ?)` ,
    [nombre, email, telefono, empresa]
  );

  return findContactById(result.insertId);
};

export const updateContact = async (idContacto, payload) => {
  const normalized = normalizePayload(payload);
  validateContactPayload(normalized);
  const { nombre, email, telefono, empresa } = normalized;
  const [result] = await query(
    `UPDATE Contacto
     SET nombre = ?, email = ?, telefono = ?, empresa = ?
     WHERE id_contacto = ?`,
    [nombre, email, telefono, empresa, idContacto]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  return findContactById(idContacto);
};

export const deleteContact = async (idContacto) => {
  const [result] = await query(`DELETE FROM Contacto WHERE id_contacto = ?`, [idContacto]);
  return result.affectedRows > 0;
};
