const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Crear un nuevo log de auditoría
router.post('/', async (req, res) => {
  try {
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
    } = req.body;

    const query = `
      INSERT INTO audit_logs (
        id_usuario, nombre_usuario, rol_usuario, accion, categoria,
        entidad, id_entidad, nombre_entidad, detalles, fecha_hora
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await db.execute(query, [
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

    res.status(201).json({
      message: 'Log de auditoría creado exitosamente',
      id_log: result.insertId
    });
  } catch (error) {
    console.error('Error al crear log de auditoría:', error);
    res.status(500).json({ error: 'Error al crear log de auditoría' });
  }
});

// Obtener todos los logs de auditoría
router.get('/', async (req, res) => {
  try {
    const query = `
      SELECT * FROM audit_logs
      ORDER BY fecha_hora DESC
      LIMIT 1000
    `;
    
    const [logs] = await db.execute(query);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs:', error);
    res.status(500).json({ error: 'Error al obtener logs de auditoría' });
  }
});

// Obtener logs por categoría (administrador/asesor)
router.get('/category/:categoria', async (req, res) => {
  try {
    const { categoria } = req.params;
    
    const query = `
      SELECT * FROM audit_logs
      WHERE categoria = ?
      ORDER BY fecha_hora DESC
      LIMIT 1000
    `;
    
    const [logs] = await db.execute(query, [categoria]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por categoría:', error);
    res.status(500).json({ error: 'Error al obtener logs por categoría' });
  }
});

// Obtener logs por usuario
router.get('/user/:id_usuario', async (req, res) => {
  try {
    const { id_usuario } = req.params;
    
    const query = `
      SELECT * FROM audit_logs
      WHERE id_usuario = ?
      ORDER BY fecha_hora DESC
      LIMIT 500
    `;
    
    const [logs] = await db.execute(query, [id_usuario]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por usuario:', error);
    res.status(500).json({ error: 'Error al obtener logs por usuario' });
  }
});

// Obtener logs por rango de fechas
router.get('/date-range', async (req, res) => {
  try {
    const { start, end } = req.query;
    
    if (!start || !end) {
      return res.status(400).json({ error: 'Se requieren fechas de inicio y fin' });
    }

    const query = `
      SELECT * FROM audit_logs
      WHERE fecha_hora BETWEEN ? AND ?
      ORDER BY fecha_hora DESC
    `;
    
    const [logs] = await db.execute(query, [start, end]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por rango de fechas:', error);
    res.status(500).json({ error: 'Error al obtener logs por rango de fechas' });
  }
});

// Obtener logs por entidad
router.get('/entity/:entidad', async (req, res) => {
  try {
    const { entidad } = req.params;
    
    const query = `
      SELECT * FROM audit_logs
      WHERE entidad = ?
      ORDER BY fecha_hora DESC
      LIMIT 500
    `;
    
    const [logs] = await db.execute(query, [entidad]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por entidad:', error);
    res.status(500).json({ error: 'Error al obtener logs por entidad' });
  }
});

// Obtener logs por entidad e ID específico
router.get('/entity/:entidad/:id_entidad', async (req, res) => {
  try {
    const { entidad, id_entidad } = req.params;
    
    const query = `
      SELECT * FROM audit_logs
      WHERE entidad = ? AND id_entidad = ?
      ORDER BY fecha_hora DESC
    `;
    
    const [logs] = await db.execute(query, [entidad, id_entidad]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por entidad e ID:', error);
    res.status(500).json({ error: 'Error al obtener logs por entidad e ID' });
  }
});

// Obtener estadísticas de auditoría
router.get('/stats', async (req, res) => {
  try {
    // Total de logs
    const [totalResult] = await db.execute('SELECT COUNT(*) as total FROM audit_logs');
    
    // Logs por categoría
    const [categoryStats] = await db.execute(`
      SELECT categoria, COUNT(*) as count
      FROM audit_logs
      GROUP BY categoria
    `);
    
    // Logs por acción
    const [actionStats] = await db.execute(`
      SELECT accion, COUNT(*) as count
      FROM audit_logs
      GROUP BY accion
      ORDER BY count DESC
      LIMIT 10
    `);
    
    // Usuarios más activos
    const [userStats] = await db.execute(`
      SELECT nombre_usuario, rol_usuario, COUNT(*) as count
      FROM audit_logs
      GROUP BY id_usuario, nombre_usuario, rol_usuario
      ORDER BY count DESC
      LIMIT 10
    `);
    
    // Actividad por día (últimos 30 días)
    const [dailyActivity] = await db.execute(`
      SELECT DATE(fecha_hora) as fecha, COUNT(*) as count
      FROM audit_logs
      WHERE fecha_hora >= DATE_SUB(NOW(), INTERVAL 30 DAY)
      GROUP BY DATE(fecha_hora)
      ORDER BY fecha DESC
    `);

    res.json({
      total: totalResult[0].total,
      byCategory: categoryStats,
      byAction: actionStats,
      topUsers: userStats,
      dailyActivity: dailyActivity
    });
  } catch (error) {
    console.error('Error al obtener estadísticas:', error);
    res.status(500).json({ error: 'Error al obtener estadísticas de auditoría' });
  }
});

// Eliminar logs antiguos (opcional - para mantenimiento)
router.delete('/cleanup/:days', async (req, res) => {
  try {
    const { days } = req.params;
    
    const query = `
      DELETE FROM audit_logs
      WHERE fecha_hora < DATE_SUB(NOW(), INTERVAL ? DAY)
    `;
    
    const [result] = await db.execute(query, [days]);
    
    res.json({
      message: `Logs anteriores a ${days} días eliminados`,
      deletedCount: result.affectedRows
    });
  } catch (error) {
    console.error('Error al limpiar logs:', error);
    res.status(500).json({ error: 'Error al limpiar logs antiguos' });
  }
});

module.exports = router;
