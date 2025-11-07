import {
  findAllClients,
  findClientById,
  findClientsByUser,
  createClient,
  updateClient,
  deleteClient,
} from '../services/clients.service.js';
import { createAuditLog } from '../services/audit.service.js';

export const getClients = async (_req, res, next) => {
  try {
    const clients = await findAllClients();
    res.json({ ok: true, clients });
  } catch (error) {
    next(error);
  }
};

export const getClientById = async (req, res, next) => {
  try {
    const { idCliente } = req.params;
    const client = await findClientById(idCliente);

    if (!client) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado' });
    }

    res.json({ ok: true, client });
  } catch (error) {
    next(error);
  }
};

export const getClientsByUser = async (req, res, next) => {
  try {
    const { idUsuario } = req.params;
    const clients = await findClientsByUser(idUsuario);
    res.json({ ok: true, clients });
  } catch (error) {
    next(error);
  }
};

export const createClientController = async (req, res, next) => {
  try {
    console.log('📦 Crear cliente - req.body.audit:', req.body.audit);
    const newClient = await createClient(req.body);
    
    // Registrar en auditoría
    if (req.body.audit) {
      try {
        await createAuditLog({
          id_usuario: req.body.audit.id_usuario,
          nombre_usuario: req.body.audit.nombre_usuario,
          rol_usuario: req.body.audit.rol_usuario,
          accion: 'Crear cliente',
          entidad: 'Cliente',
          id_entidad: newClient.id_cliente,
          nombre_entidad: `${newClient.nombres || ''} ${newClient.apellidos || ''}`.trim(),
          categoria: req.body.audit.categoria || 'administrador',
          detalles: JSON.stringify({
            nombres: newClient.nombres,
            apellidos: newClient.apellidos,
            email: newClient.email,
            telefono: newClient.telefono,
          })
        });
      } catch (auditError) {
        console.error('Error al registrar auditoría:', auditError);
      }
    }
    
    res.status(201).json({ ok: true, client: newClient });
  } catch (error) {
    next(error);
  }
};

export const updateClientController = async (req, res, next) => {
  try {
    console.log('📦 Actualizar cliente - req.body.audit:', req.body.audit);
    const { idCliente } = req.params;
    const updatedClient = await updateClient(idCliente, req.body);

    if (!updatedClient) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado' });
    }

    // Registrar en auditoría
    if (req.body.audit) {
      try {
        console.log('✅ Registrando auditoría de edición...');
        const auditData = {
          id_usuario: req.body.audit.id_usuario,
          nombre_usuario: req.body.audit.nombre_usuario,
          rol_usuario: req.body.audit.rol_usuario,
          accion: 'Editar cliente',
          entidad: 'Cliente',
          id_entidad: parseInt(idCliente),
          nombre_entidad: `${updatedClient.nombres || updatedClient.nombre || ''} ${updatedClient.apellidos || updatedClient.apellido || ''}`.trim(),
          categoria: req.body.audit.categoria || 'administrador',
          detalles: JSON.stringify({
            nombres: updatedClient.nombres || updatedClient.nombre,
            apellidos: updatedClient.apellidos || updatedClient.apellido,
            email: updatedClient.email,
            telefono: updatedClient.telefono,
          })
        };
        console.log('📝 Datos de auditoría:', auditData);
        await createAuditLog(auditData);
        console.log('✅ Auditoría registrada exitosamente');
      } catch (auditError) {
        console.error('❌ Error al registrar auditoría:', auditError);
      }
    } else {
      console.log('⚠️ No se recibieron datos de auditoría');
    }

    res.json({ ok: true, client: updatedClient });
  } catch (error) {
    next(error);
  }
};

export const deleteClientController = async (req, res, next) => {
  try {
    const { idCliente } = req.params;
    
    console.log('📦 Eliminar cliente - query params:', req.query);
    
    // Obtener datos del cliente antes de eliminarlo para la auditoría
    const clientToDelete = await findClientById(idCliente);
    
    const deleted = await deleteClient(idCliente);

    if (!deleted) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado' });
    }

    // Registrar en auditoría - leer desde query params
    if (req.query.id_usuario && clientToDelete) {
      try {
        console.log('✅ Registrando auditoría de eliminación...');
        const auditData = {
          id_usuario: parseInt(req.query.id_usuario),
          nombre_usuario: req.query.nombre_usuario,
          rol_usuario: req.query.rol_usuario,
          accion: 'Eliminar cliente',
          entidad: 'Cliente',
          id_entidad: parseInt(idCliente),
          nombre_entidad: `${clientToDelete.nombres || ''} ${clientToDelete.apellidos || ''}`.trim(),
          categoria: req.query.categoria || 'administrador',
          detalles: JSON.stringify({
            nombres: clientToDelete.nombres,
            apellidos: clientToDelete.apellidos,
            email: clientToDelete.email,
          })
        };
        console.log('📝 Datos de auditoría:', auditData);
        await createAuditLog(auditData);
        console.log('✅ Auditoría de eliminación registrada exitosamente');
      } catch (auditError) {
        console.error('❌ Error al registrar auditoría de eliminación:', auditError);
      }
    } else {
      console.log('⚠️ No se recibieron datos de auditoría para eliminación');
    }

    res.json({ ok: true, deleted: true });
  } catch (error) {
    next(error);
  }
};
