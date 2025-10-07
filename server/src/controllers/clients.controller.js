import {
  findAllClients,
  findClientById,
  findClientsByUser,
  createClient,
  updateClient,
  deleteClient,
} from '../services/clients.service.js';

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
