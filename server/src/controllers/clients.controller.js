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
    const newClient = await createClient(req.body);
    res.status(201).json({ ok: true, client: newClient });
  } catch (error) {
    next(error);
  }
};

export const updateClientController = async (req, res, next) => {
  try {
    const { idCliente } = req.params;
    const updatedClient = await updateClient(idCliente, req.body);

    if (!updatedClient) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado' });
    }

    // Registrar en auditoría
    if (req.body.audit) {
      try {
        await createAuditLog({
          id_usuario: req.body.audit.id_usuario,
          nombre_usuario: req.body.audit.nombre_usuario,
          rol_usuario: req.body.audit.rol_usuario,
          accion: 'Editar',
          entidad: 'Cliente',
          id_entidad: parseInt(idCliente),
          nombre_entidad: `${updatedClient.nombre} ${updatedClient.apellido}`,
          categoria: req.body.audit.categoria || 'administrador',
          detalles: JSON.stringify({
            nombre: updatedClient.nombre,
            apellido: updatedClient.apellido,
            email: updatedClient.email,
            telefono: updatedClient.telefono,
            origen: updatedClient.origen
          })
        });
      } catch (auditError) {
        console.error('Error al registrar auditoría:', auditError);
      }
    }

    res.json({ ok: true, client: updatedClient });
  } catch (error) {
    next(error);
  }
};

export const deleteClientController = async (req, res, next) => {
  try {
    const { idCliente } = req.params;
    const deleted = await deleteClient(idCliente);

    if (!deleted) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado' });
    }

    res.json({ ok: true, deleted: true });
  } catch (error) {
    next(error);
  }
};
