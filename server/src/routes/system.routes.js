import { Router } from 'express';
import { query } from '../config/db.js';
import { createAuditLog } from '../services/audit.service.js';

const router = Router();

/**
 * Limpiar todo el CRM - Solo superadministrador
 * DELETE /api/system/clear-all
 */
router.delete('/clear-all', async (req, res) => {
  try {
    console.log('🗑️ Iniciando limpieza completa del CRM...');
    console.log('📦 Datos de auditoría:', req.query);

    // Registrar en auditoría ANTES de limpiar
    if (req.query.id_usuario) {
      try {
        await createAuditLog({
          id_usuario: parseInt(req.query.id_usuario),
          nombre_usuario: req.query.nombre_usuario,
          rol_usuario: req.query.rol_usuario,
          accion: 'Limpiar CRM',
          entidad: 'Sistema',
          id_entidad: null,
          nombre_entidad: 'Sistema completo',
          categoria: req.query.categoria || 'administrador',
          detalles: JSON.stringify({
            accion: 'Limpieza completa del CRM',
            fecha: new Date().toISOString(),
          })
        });
        console.log('✅ Auditoría de limpieza registrada');
      } catch (auditError) {
        console.error('❌ Error al registrar auditoría:', auditError);
      }
    }

    // Limpiar todas las tablas en orden (respetando foreign keys)
    await query('DELETE FROM payments');
    console.log('✅ Pagos eliminados');
    
    await query('DELETE FROM reservations');
    console.log('✅ Reservas eliminadas');
    
    await query('DELETE FROM quotations');
    console.log('✅ Cotizaciones eliminadas');
    
    await query('DELETE FROM clients');
    console.log('✅ Clientes eliminados');
    
    await query('DELETE FROM packages');
    console.log('✅ Paquetes eliminados');
    
    await query('DELETE FROM destinations');
    console.log('✅ Destinos eliminados');
    
    await query('DELETE FROM contacts');
    console.log('✅ Contactos eliminados');
    
    await query('DELETE FROM suppliers');
    console.log('✅ Proveedores eliminados');
    
    // NO eliminar usuarios ni logs de acceso/auditoría para mantener historial
    console.log('✅ Limpieza completa del CRM finalizada');

    res.json({ 
      ok: true, 
      message: 'CRM limpiado exitosamente',
      cleared: {
        payments: true,
        reservations: true,
        quotations: true,
        clients: true,
        packages: true,
        destinations: true,
        contacts: true,
        suppliers: true,
      }
    });
  } catch (error) {
    console.error('❌ Error al limpiar CRM:', error);
    res.status(500).json({ 
      ok: false, 
      error: 'Error al limpiar el CRM',
      details: error.message 
    });
  }
});

export default router;
