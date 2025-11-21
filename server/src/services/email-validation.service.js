import { query } from '../config/db.js';

/**
 * Validar si un email ya existe en el sistema (Usuario, Cliente o Proveedor)
 * @param {string} email - Email a validar
 * @param {Object} options - Opciones de validación
 * @param {string} options.excludeTable - Tabla a excluir de la búsqueda ('Usuario', 'Cliente', 'Proveedor')
 * @param {number} options.excludeId - ID a excluir de la búsqueda
 * @returns {Promise<Object|null>} Objeto con información de dónde existe el email, o null si no existe
 */
export const checkEmailExists = async (email, options = {}) => {
  const { excludeTable, excludeId } = options;

  // Buscar en Usuario
  if (excludeTable !== 'Usuario') {
    let whereClause = 'correo = ?';
    const params = [email];
    
    if (excludeTable === 'Usuario' && excludeId) {
      whereClause += ' AND id_usuario <> ?';
      params.push(excludeId);
    }

    const [usuarios] = await query(
      `SELECT id_usuario, nombre, apellido, correo FROM Usuario WHERE ${whereClause} LIMIT 1`,
      params
    );

    if (usuarios.length > 0) {
      return {
        exists: true,
        table: 'Usuario',
        entity: 'usuario',
        displayName: 'Usuario',
        data: usuarios[0]
      };
    }
  }

  // Buscar en Cliente
  if (excludeTable !== 'Cliente') {
    let whereClause = 'email = ?';
    const params = [email];
    
    if (excludeTable === 'Cliente' && excludeId) {
      whereClause += ' AND id_cliente <> ?';
      params.push(excludeId);
    }

    const [clientes] = await query(
      `SELECT id_cliente, nombres, apellidos, email FROM Cliente WHERE ${whereClause} LIMIT 1`,
      params
    );

    if (clientes.length > 0) {
      return {
        exists: true,
        table: 'Cliente',
        entity: 'cliente',
        displayName: 'Cliente',
        data: clientes[0]
      };
    }
  }

  // Buscar en Proveedor
  if (excludeTable !== 'Proveedor') {
    let whereClause = 'correo = ?';
    const params = [email];
    
    if (excludeTable === 'Proveedor' && excludeId) {
      whereClause += ' AND id_proveedor <> ?';
      params.push(excludeId);
    }

    const [proveedores] = await query(
      `SELECT id_proveedor, nombre, correo FROM Proveedores WHERE ${whereClause} LIMIT 1`,
      params
    );

    if (proveedores.length > 0) {
      return {
        exists: true,
        table: 'Proveedor',
        entity: 'proveedor',
        displayName: 'Proveedor',
        data: proveedores[0]
      };
    }
  }

  return null;
};

/**
 * Validar email y lanzar error si ya existe
 * @param {string} email - Email a validar
 * @param {Object} options - Opciones de validación
 * @throws {Error} Si el email ya existe
 */
export const validateEmailUnique = async (email, options = {}) => {
  const result = await checkEmailExists(email, options);
  
  if (result) {
    const error = new Error(
      `El email ya está registrado en el sistema como ${result.displayName}`
    );
    error.status = 409;
    error.conflict = result;
    throw error;
  }
};
