import {
  findAllDestinations,
  findDestinationById,
  createDestination,
  updateDestination,
  deleteDestination,
} from '../services/destinations.service.js';

export const getDestinations = async (_req, res, next) => {
  try {
    const destinations = await findAllDestinations();
    res.json({ ok: true, destinations });
  } catch (error) {
    next(error);
  }
};

export const getDestinationById = async (req, res, next) => {
  try {
    const { idDestino } = req.params;
    const destination = await findDestinationById(idDestino);

    if (!destination) {
      return res.status(404).json({ ok: false, error: 'Destino no encontrado' });
    }

    res.json({ ok: true, destination });
  } catch (error) {
    next(error);
  }
};

export const createDestinationController = async (req, res, next) => {
  try {
    const newDestination = await createDestination(req.body);
    res.status(201).json({ ok: true, destination: newDestination });
  } catch (error) {
    next(error);
  }
};

export const updateDestinationController = async (req, res, next) => {
  try {
    const { idDestino } = req.params;
    const updatedDestination = await updateDestination(idDestino, req.body);

    if (!updatedDestination) {
      return res.status(404).json({ ok: false, error: 'Destino no encontrado' });
    }

    res.json({ ok: true, destination: updatedDestination });
  } catch (error) {
    next(error);
  }
};

export const deleteDestinationController = async (req, res, next) => {
  try {
    const { idDestino } = req.params;
    const deleted = await deleteDestination(idDestino);

    if (!deleted) {
      return res.status(404).json({ ok: false, error: 'Destino no encontrado' });
    }

    res.json({ ok: true, deleted: true });
  } catch (error) {
    next(error);
  }
};
