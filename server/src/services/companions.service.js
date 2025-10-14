import { query, getConnection } from '../config/db.js';

/**
 * Servicio para gestionar acompañantes de cotizaciones
 */

/**
 * Mapea un registro de la BD a un objeto de acompañante
 */
const mapDbCompanion = (row) => {
  if (!row) return null;

  return {
    id: row.id_acompanante,
    id_acompanante: row.id_acompanante,
    nombres: row.nombres,
    apellidos: row.apellidos,
    nombreCompleto: `${row.nombres || ''} ${row.apellidos || ''}`.trim(),
    documento: row.documento,
    nacionalidad: row.nacionalidad,
    fecha_nacimiento: row.fecha_nacimiento,
    fechaNacimiento: row.fecha_nacimiento,
    es_menor: row.es_menor === 1 || row.es_menor === true,
    esMenor: row.es_menor === 1 || row.es_menor === true,
    id_cotizacion: row.id_cotizacion,
    idCotizacion: row.id_cotizacion,
    fecha_registro: row.fecha_registro,
    fechaRegistro: row.fecha_registro,
  };
};

/**
 * Obtener todos los acompañantes de una cotización
 */
export const findCompanionsByQuote = async (idCotizacion) => {
  const [rows] = await query(
    `SELECT * FROM Acompanante 
     WHERE id_cotizacion = ? 
     ORDER BY fecha_registro ASC`,
    [idCotizacion]
  );
  return rows.map(mapDbCompanion);
};

/**
 * Obtener un acompañante por ID
 */
export const findCompanionById = async (idAcompanante) => {
  const [rows] = await query(
    'SELECT * FROM Acompanante WHERE id_acompanante = ? LIMIT 1',
    [idAcompanante]
  );
  return mapDbCompanion(rows[0]);
};

/**
 * Crear un nuevo acompañante
 */
export const createCompanion = async (companionData) => {
  const connection = await getConnection();

  try {
    const [result] = await connection.execute(
      `INSERT INTO Acompanante (
        nombres,
        apellidos,
        documento,
        nacionalidad,
        fecha_nacimiento,
        es_menor,
        id_cotizacion,
        fecha_registro
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        companionData.nombres,
        companionData.apellidos,
        companionData.documento || null,
        companionData.nacionalidad || 'Perú',
        companionData.fecha_nacimiento || null,
        companionData.es_menor || false,
        companionData.id_cotizacion,
        new Date(),
      ]
    );

    // Obtener el acompañante recién creado
    const [createdCompanion] = await connection.query(
      'SELECT * FROM Acompanante WHERE id_acompanante = ?',
      [result.insertId]
    );

    return mapDbCompanion(createdCompanion[0]);
  } catch (error) {
    console.error('Error al crear acompañante:', error);
    throw error;
  } finally {
    connection.release();
  }
};

/**
 * Actualizar un acompañante existente
 */
export const updateCompanion = async (idAcompanante, companionData) => {
  const existingCompanion = await findCompanionById(idAcompanante);
  if (!existingCompanion) return null;

  const connection = await getConnection();

  try {
    const fields = [];
    const values = [];

    const updatableFields = [
      { column: 'nombres', key: 'nombres' },
      { column: 'apellidos', key: 'apellidos' },
      { column: 'documento', key: 'documento' },
      { column: 'nacionalidad', key: 'nacionalidad' },
      { column: 'fecha_nacimiento', key: 'fecha_nacimiento' },
      { column: 'es_menor', key: 'es_menor' },
    ];

    for (const { column, key } of updatableFields) {
      if (companionData[key] !== undefined) {
        fields.push(`${column} = ?`);
        values.push(companionData[key]);
      }
    }

    if (!fields.length) {
      return existingCompanion;
    }

    values.push(idAcompanante);

    await connection.execute(
      `UPDATE Acompanante SET ${fields.join(', ')} WHERE id_acompanante = ?`,
      values
    );

    return await findCompanionById(idAcompanante);
  } catch (error) {
    console.error('Error actualizando acompañante:', error);
    throw error;
  } finally {
    connection.release();
  }
};

/**
 * Eliminar un acompañante
 */
export const deleteCompanion = async (idAcompanante) => {
  const companion = await findCompanionById(idAcompanante);
  if (!companion) return false;

  const connection = await getConnection();

  try {
    const [result] = await connection.execute(
      'DELETE FROM Acompanante WHERE id_acompanante = ?',
      [idAcompanante]
    );
    return result.affectedRows > 0;
  } finally {
    connection.release();
  }
};

/**
 * Eliminar todos los acompañantes de una cotización
 */
export const deleteCompanionsByQuote = async (idCotizacion) => {
  const connection = await getConnection();

  try {
    const [result] = await connection.execute(
      'DELETE FROM Acompanante WHERE id_cotizacion = ?',
      [idCotizacion]
    );
    return result.affectedRows;
  } finally {
    connection.release();
  }
};

/**
 * Crear múltiples acompañantes para una cotización
 */
export const createMultipleCompanions = async (idCotizacion, companions) => {
  if (!companions || companions.length === 0) {
    return [];
  }

  const createdCompanions = [];

  for (const companionData of companions) {
    const companion = await createCompanion({
      ...companionData,
      id_cotizacion: idCotizacion,
    });
    createdCompanions.push(companion);
  }

  return createdCompanions;
};

/**
 * Actualizar acompañantes de una cotización
 * Elimina los existentes y crea los nuevos
 */
export const updateCompanionsByQuote = async (idCotizacion, companions) => {
  // Eliminar acompañantes existentes
  await deleteCompanionsByQuote(idCotizacion);

  // Crear los nuevos acompañantes
  if (companions && companions.length > 0) {
    return await createMultipleCompanions(idCotizacion, companions);
  }

  return [];
};
