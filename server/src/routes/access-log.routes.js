import express from 'express';
import { query } from '../config/db.js';

const router = express.Router();

// Crear un nuevo log de acceso (login)
router.post('/', async (req, res) => {
  try {
    const {
      id_usuario,
      nombre_usuario,
      rol_usuario,
      fecha_hora_ingreso,
      ip_address,
      navegador,
      sistema_operativo
    } = req.body;

    const sql = `
      INSERT INTO access_logs (
        id_usuario, nombre_usuario, rol_usuario, fecha_hora_ingreso,
        ip_address, navegador, sistema_operativo
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await query(sql, [
      id_usuario,
      nombre_usuario,
      rol_usuario,
      fecha_hora_ingreso || new Date(),
      ip_address,
      navegador || null,
      sistema_operativo || null
    ]);

    res.status(201).json({
      message: 'Log de acceso creado exitosamente',
      id_log: result.insertId
    });
  } catch (error) {
    console.error('Error al crear log de acceso:', error);
    res.status(500).json({ error: 'Error al crear log de acceso' });
  }
});

// Registrar salida (logout)
router.put('/:id/logout', async (req, res) => {
  try {
    const { id } = req.params;
    const fechaHoraSalida = new Date();

    // Obtener la fecha de ingreso para calcular duración
    const [logs] = await query(
      'SELECT fecha_hora_ingreso FROM access_logs WHERE id_log = ?',
      [id]
    );

    if (logs.length === 0) {
      return res.status(404).json({ error: 'Log no encontrado' });
    }

    const fechaIngreso = new Date(logs[0].fecha_hora_ingreso);
    
    // Calcular duración en milisegundos
    const duracionMs = fechaHoraSalida.getTime() - fechaIngreso.getTime();
    
    // Convertir a horas y minutos
    const totalMinutes = Math.floor(duracionMs / (1000 * 60));
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    
    // Formatear duración
    let duracionSesion;
    if (hours > 0) {
      duracionSesion = `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
      duracionSesion = `${minutes}m`;
    } else {
      duracionSesion = 'Menos de 1m';
    }

    console.log(`📊 Duración calculada: ${duracionSesion} (${totalMinutes} minutos)`);

    const sql = `
      UPDATE access_logs
      SET fecha_hora_salida = ?, duracion_sesion = ?
      WHERE id_log = ?
    `;

    await query(sql, [fechaHoraSalida, duracionSesion, id]);

    res.json({
      message: 'Salida registrada exitosamente',
      duracion_sesion: duracionSesion
    });
  } catch (error) {
    console.error('Error al registrar salida:', error);
    res.status(500).json({ error: 'Error al registrar salida' });
  }
});

// Obtener todos los logs de acceso
router.get('/', async (req, res) => {
  try {
    const sql = `
      SELECT * FROM access_logs
      ORDER BY fecha_hora_ingreso DESC
      LIMIT 1000
    `;
    
    const [logs] = await query(sql);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs:', error);
    res.status(500).json({ error: 'Error al obtener logs de acceso' });
  }
});

// Obtener logs por usuario
router.get('/user/:id_usuario', async (req, res) => {
  try {
    const { id_usuario } = req.params;
    
    const sql = `
      SELECT * FROM access_logs
      WHERE id_usuario = ?
      ORDER BY fecha_hora_ingreso DESC
      LIMIT 500
    `;
    
    const [logs] = await query(sql, [id_usuario]);
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

    const sql = `
      SELECT * FROM access_logs
      WHERE fecha_hora_ingreso BETWEEN ? AND ?
      ORDER BY fecha_hora_ingreso DESC
    `;
    
    const [logs] = await query(sql, [start, end]);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener logs por rango de fechas:', error);
    res.status(500).json({ error: 'Error al obtener logs por rango de fechas' });
  }
});

// Obtener sesiones activas
router.get('/active', async (req, res) => {
  try {
    const sql = `
      SELECT * FROM access_logs
      WHERE fecha_hora_salida IS NULL
      ORDER BY fecha_hora_ingreso DESC
    `;
    
    const [logs] = await query(sql);
    res.json(logs);
  } catch (error) {
    console.error('Error al obtener sesiones activas:', error);
    res.status(500).json({ error: 'Error al obtener sesiones activas' });
  }
});

// Obtener estadísticas de acceso
router.get('/stats', async (req, res) => {
  try {
    // Total de accesos
    const [totalResult] = await query('SELECT COUNT(*) as total FROM access_logs');
    
    // Sesiones activas
    const [activeResult] = await query(
      'SELECT COUNT(*) as active FROM access_logs WHERE fecha_hora_salida IS NULL'
    );
    
    // Accesos por rol
    const [roleStats] = await query(`
      SELECT rol_usuario, COUNT(*) as count
      FROM access_logs
      GROUP BY rol_usuario
    `);
    
    // Usuarios más activos
    const [userStats] = await query(`
      SELECT nombre_usuario, rol_usuario, COUNT(*) as count
      FROM access_logs
      GROUP BY id_usuario, nombre_usuario, rol_usuario
      ORDER BY count DESC
      LIMIT 10
    `);
    
    // Accesos por día (últimos 30 días)
    const [dailyAccess] = await query(`
      SELECT DATE(fecha_hora_ingreso) as fecha, COUNT(*) as count
      FROM access_logs
      WHERE fecha_hora_ingreso >= DATE_SUB(NOW(), INTERVAL 30 DAY)
      GROUP BY DATE(fecha_hora_ingreso)
      ORDER BY fecha DESC
    `);

    res.json({
      total: totalResult[0].total,
      activeSessions: activeResult[0].active,
      byRole: roleStats,
      topUsers: userStats,
      dailyAccess: dailyAccess
    });
  } catch (error) {
    console.error('Error al obtener estadísticas:', error);
    res.status(500).json({ error: 'Error al obtener estadísticas de acceso' });
  }
});

// Eliminar todos los logs de acceso
router.delete('/', async (req, res) => {
  try {
    const sql = 'DELETE FROM access_logs';
    await query(sql);
    
    res.json({ 
      message: 'Todos los registros de acceso han sido eliminados exitosamente',
      success: true 
    });
  } catch (error) {
    console.error('Error al eliminar logs de acceso:', error);
    res.status(500).json({ error: 'Error al eliminar logs de acceso' });
  }
});

export default router;
