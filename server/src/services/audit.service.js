import { query } from '../config/db.js';

/**
 * Crear un log de auditoría
 * @param {Object} logData - Datos del log de auditoría
 * @returns {Promise<number>} ID del log creado
 */
export const createAuditLog = async (logData) => {
  const {
    id_usuario,
    nombre_usuario,
    rol_usuario,
    accion,
    categoria,
    entidad,
    id_entidad,
    nombre_entidad,
    detalles,
    fecha_hora
  } = logData;

  const sql = `
    INSERT INTO audit_logs (
      id_usuario, nombre_usuario, rol_usuario, accion, categoria,
      entidad, id_entidad, nombre_entidad, detalles, fecha_hora
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const [result] = await query(sql, [
    id_usuario,
    nombre_usuario,
    rol_usuario,
    accion,
    categoria,
    entidad,
    id_entidad || null,
    nombre_entidad || null,
    detalles || null,
    fecha_hora || new Date()
  ]);

  return result.insertId;
};

/**
 * Obtener todos los logs de auditoría
 * @param {number} limit - Límite de resultados
 * @returns {Promise<Array>} Array de logs
 */
export const getAllAuditLogs = async (limit = 1000) => {
  const sql = `
    SELECT * FROM audit_logs
    ORDER BY fecha_hora DESC
    LIMIT ?
  `;
  
  const [logs] = await query(sql, [limit]);
  return logs;
};

/**
 * Obtener logs por categoría
 * @param {string} categoria - Categoría (administrador/asesor)
 * @param {number} limit - Límite de resultados
 * @returns {Promise<Array>} Array de logs
 */
export const getAuditLogsByCategory = async (categoria, limit = 1000) => {
  const sql = `
    SELECT * FROM audit_logs
    WHERE categoria = ?
    ORDER BY fecha_hora DESC
    LIMIT ?
  `;
  
  const [logs] = await query(sql, [categoria, limit]);
  return logs;
};

/**
 * Obtener logs por usuario
 * @param {number} id_usuario - ID del usuario
 * @param {number} limit - Límite de resultados
 * @returns {Promise<Array>} Array de logs
 */
export const getAuditLogsByUser = async (id_usuario, limit = 500) => {
  const sql = `
    SELECT * FROM audit_logs
    WHERE id_usuario = ?
    ORDER BY fecha_hora DESC
    LIMIT ?
  `;
  
  const [logs] = await query(sql, [id_usuario, limit]);
  return logs;
};

/**
 * Obtener logs por entidad
 * @param {string} entidad - Nombre de la entidad
 * @param {number} id_entidad - ID de la entidad (opcional)
 * @param {number} limit - Límite de resultados
 * @returns {Promise<Array>} Array de logs
 */
export const getAuditLogsByEntity = async (entidad, id_entidad = null, limit = 500) => {
  let sql = `
    SELECT * FROM audit_logs
    WHERE entidad = ?
  `;
  
  const params = [entidad];
  
  if (id_entidad !== null) {
    sql += ' AND id_entidad = ?';
    params.push(id_entidad);
  }
  
  sql += ' ORDER BY fecha_hora DESC LIMIT ?';
  params.push(limit);
  
  const [logs] = await query(sql, params);
  return logs;
};

/**
 * Obtener logs por rango de fechas
 * @param {Date} startDate - Fecha de inicio
 * @param {Date} endDate - Fecha de fin
 * @returns {Promise<Array>} Array de logs
 */
export const getAuditLogsByDateRange = async (startDate, endDate) => {
  const sql = `
    SELECT * FROM audit_logs
    WHERE fecha_hora BETWEEN ? AND ?
    ORDER BY fecha_hora DESC
  `;
  
  const [logs] = await query(sql, [startDate, endDate]);
  return logs;
};

/**
 * Eliminar todos los logs de auditoría
 * @returns {Promise<number>} Número de registros eliminados
 */
export const deleteAllAuditLogs = async () => {
  const sql = 'DELETE FROM audit_logs';
  const [result] = await query(sql);
  return result.affectedRows;
};

/**
 * Eliminar logs antiguos
 * @param {number} days - Días de antigüedad
 * @returns {Promise<number>} Número de registros eliminados
 */
export const deleteOldAuditLogs = async (days) => {
  const sql = `
    DELETE FROM audit_logs
    WHERE fecha_hora < DATE_SUB(NOW(), INTERVAL ? DAY)
  `;
  
  const [result] = await query(sql, [days]);
  return result.affectedRows;
};

/**
 * Obtener estadísticas de auditoría
 * @returns {Promise<Object>} Objeto con estadísticas
 */
export const getAuditStats = async () => {
  // Total de logs
  const [totalResult] = await query('SELECT COUNT(*) as total FROM audit_logs');
  
  // Logs por categoría
  const [categoryStats] = await query(`
    SELECT categoria, COUNT(*) as count
    FROM audit_logs
    GROUP BY categoria
  `);
  
  // Logs por acción
  const [actionStats] = await query(`
    SELECT accion, COUNT(*) as count
    FROM audit_logs
    GROUP BY accion
    ORDER BY count DESC
    LIMIT 10
  `);
  
  // Usuarios más activos
  const [userStats] = await query(`
    SELECT nombre_usuario, rol_usuario, COUNT(*) as count
    FROM audit_logs
    GROUP BY id_usuario, nombre_usuario, rol_usuario
    ORDER BY count DESC
    LIMIT 10
  `);
  
  // Actividad por día (últimos 30 días)
  const [dailyActivity] = await query(`
    SELECT DATE(fecha_hora) as fecha, COUNT(*) as count
    FROM audit_logs
    WHERE fecha_hora >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY DATE(fecha_hora)
    ORDER BY fecha DESC
  `);

  return {
    total: totalResult[0].total,
    byCategory: categoryStats,
    byAction: actionStats,
    topUsers: userStats,
    dailyActivity: dailyActivity
  };
};
