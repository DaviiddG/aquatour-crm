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
  let whereClause = 'correo = ?';
  let params = [email];
  
  // Si estamos editando un usuario, excluir su propio ID
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

  // Buscar en Cliente
  whereClause = 'email = ?';
  params = [email];
  
  // Si estamos editando un cliente, excluir su propio ID
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

  // Buscar en Proveedor
  whereClause = 'correo = ?';
  params = [email];
  
  // Si estamos editando un proveedor, excluir su propio ID
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

  // Buscar en Contacto
  whereClause = 'email = ?';
  params = [email];
  
  // Si estamos editando un contacto, excluir su propio ID
  if (excludeTable === 'Contacto' && excludeId) {
    whereClause += ' AND id_contacto <> ?';
    params.push(excludeId);
  }

  const [contactos] = await query(
    `SELECT id_contacto, nombre, email FROM Contacto WHERE ${whereClause} LIMIT 1`,
    params
  );

  if (contactos.length > 0) {
    return {
      exists: true,
      table: 'Contacto',
      entity: 'contacto',
      displayName: 'Contacto',
      data: contactos[0]
    };
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

/**
 * Validar si un teléfono ya existe en el sistema (Usuario, Cliente o Proveedor)
 * @param {string} telefono - Teléfono a validar
 * @param {Object} options - Opciones de validación
 * @param {string} options.excludeTable - Tabla a excluir de la búsqueda ('Usuario', 'Cliente', 'Proveedor')
 * @param {number} options.excludeId - ID a excluir de la búsqueda
 * @returns {Promise<Object|null>} Objeto con información de dónde existe el teléfono, o null si no existe
 */
export const checkPhoneExists = async (telefono, options = {}) => {
  const { excludeTable, excludeId } = options;

  // Limpiar el teléfono (solo dígitos)
  const cleanPhone = String(telefono).replace(/[^0-9]/g, '');
  
  if (!cleanPhone) {
    return null;
  }

  // Buscar en Usuario
  let whereClause = 'telefono = ?';
  let params = [cleanPhone];
  
  // Si estamos editando un usuario, excluir su propio ID
  if (excludeTable === 'Usuario' && excludeId) {
    whereClause += ' AND id_usuario <> ?';
    params.push(excludeId);
  }

  const [usuarios] = await query(
    `SELECT id_usuario, nombre, apellido, telefono FROM Usuario WHERE ${whereClause} LIMIT 1`,
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

  // Buscar en Cliente
  whereClause = 'telefono = ?';
  params = [cleanPhone];
  
  // Si estamos editando un cliente, excluir su propio ID
  if (excludeTable === 'Cliente' && excludeId) {
    whereClause += ' AND id_cliente <> ?';
    params.push(excludeId);
  }

  const [clientes] = await query(
    `SELECT id_cliente, nombres, apellidos, telefono FROM Cliente WHERE ${whereClause} LIMIT 1`,
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

  // Buscar en Proveedor
  whereClause = 'telefono = ?';
  params = [cleanPhone];
  
  // Si estamos editando un proveedor, excluir su propio ID
  if (excludeTable === 'Proveedor' && excludeId) {
    whereClause += ' AND id_proveedor <> ?';
    params.push(excludeId);
  }

  const [proveedores] = await query(
    `SELECT id_proveedor, nombre, telefono FROM Proveedores WHERE ${whereClause} LIMIT 1`,
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

  // Buscar en Contacto
  whereClause = 'telefono = ?';
  params = [cleanPhone];
  
  // Si estamos editando un contacto, excluir su propio ID
  if (excludeTable === 'Contacto' && excludeId) {
    whereClause += ' AND id_contacto <> ?';
    params.push(excludeId);
  }

  const [contactos] = await query(
    `SELECT id_contacto, nombre, telefono FROM Contacto WHERE ${whereClause} LIMIT 1`,
    params
  );

  if (contactos.length > 0) {
    return {
      exists: true,
      table: 'Contacto',
      entity: 'contacto',
      displayName: 'Contacto',
      data: contactos[0]
    };
  }

  return null;
};

/**
 * Validar teléfono y lanzar error si ya existe
 * @param {string} telefono - Teléfono a validar
 * @param {Object} options - Opciones de validación
 * @throws {Error} Si el teléfono ya existe
 */
export const validatePhoneUnique = async (telefono, options = {}) => {
  const result = await checkPhoneExists(telefono, options);
  
  if (result) {
    const error = new Error(
      `El número de teléfono ya está registrado en el sistema como ${result.displayName}`
    );
    error.status = 409;
    error.conflict = result;
    throw error;
  }
};

/**
 * Validar si un documento ya existe en el sistema (Usuario o Cliente)
 * @param {string} documento - Documento a validar
 * @param {Object} options - Opciones de validación
 * @param {string} options.excludeTable - Tabla a excluir de la búsqueda ('Usuario', 'Cliente')
 * @param {number} options.excludeId - ID a excluir de la búsqueda
 * @returns {Promise<Object|null>} Objeto con información de dónde existe el documento, o null si no existe
 */
export const checkDocumentExists = async (documento, options = {}) => {
  const { excludeTable, excludeId } = options;

  // Limpiar el documento (solo alfanuméricos)
  const cleanDoc = String(documento).replace(/[^a-zA-Z0-9]/g, '');
  
  if (!cleanDoc) {
    return null;
  }

  // Buscar en Usuario
  let whereClause = 'num_documento = ?';
  let params = [cleanDoc];
  
  // Si estamos editando un usuario, excluir su propio ID
  if (excludeTable === 'Usuario' && excludeId) {
    whereClause += ' AND id_usuario <> ?';
    params.push(excludeId);
  }

  const [usuarios] = await query(
    `SELECT id_usuario, nombre, apellido, num_documento FROM Usuario WHERE ${whereClause} LIMIT 1`,
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

  // Buscar en Cliente
  whereClause = 'documento = ?';
  params = [cleanDoc];
  
  // Si estamos editando un cliente, excluir su propio ID
  if (excludeTable === 'Cliente' && excludeId) {
    whereClause += ' AND id_cliente <> ?';
    params.push(excludeId);
  }

  const [clientes] = await query(
    `SELECT id_cliente, nombres, apellidos, documento FROM Cliente WHERE ${whereClause} LIMIT 1`,
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

  return null;
};

/**
 * Validar documento y lanzar error si ya existe
 * @param {string} documento - Documento a validar
 * @param {Object} options - Opciones de validación
 * @throws {Error} Si el documento ya existe
 */
export const validateDocumentUnique = async (documento, options = {}) => {
  const result = await checkDocumentExists(documento, options);
  
  if (result) {
    const error = new Error(
      `El número de documento ya está registrado en el sistema como ${result.displayName}`
    );
    error.status = 409;
    error.conflict = result;
    throw error;
  }
};
