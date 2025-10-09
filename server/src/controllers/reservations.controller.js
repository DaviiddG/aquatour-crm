import {
  findAllReservations,
  findReservationById,
  findReservationsByEmployee,
  createReservation,
  updateReservation,
  deleteReservation,
} from '../services/reservations.service.js';

export const getReservations = async (_req, res, next) => {
  try {
    const reservations = await findAllReservations();
    res.json({ ok: true, reservations });
  } catch (error) {
    next(error);
  }
};

export const getReservationById = async (req, res, next) => {
  try {
    const { idReserva } = req.params;
    const reservation = await findReservationById(idReserva);

    if (!reservation) {
      return res.status(404).json({ ok: false, error: 'Reserva no encontrada' });
    }

    res.json({ ok: true, reservation });
  } catch (error) {
    next(error);
  }
};

export const getReservationsByEmployee = async (req, res, next) => {
  try {
    const { idEmpleado } = req.params;
    const reservations = await findReservationsByEmployee(idEmpleado);
    res.json({ ok: true, reservations });
  } catch (error) {
    next(error);
  }
};

export const createReservationController = async (req, res, next) => {
  try {
    const newReservation = await createReservation(req.body);
    res.status(201).json({ ok: true, reservation: newReservation });
  } catch (error) {
    next(error);
  }
};

export const updateReservationController = async (req, res, next) => {
  try {
    const { idReserva } = req.params;
    const updatedReservation = await updateReservation(idReserva, req.body);

    if (!updatedReservation) {
      return res.status(404).json({ ok: false, error: 'Reserva no encontrada' });
    }

    res.json({ ok: true, reservation: updatedReservation });
  } catch (error) {
    next(error);
  }
};

export const deleteReservationController = async (req, res, next) => {
  try {
    const { idReserva } = req.params;
    await deleteReservation(idReserva);
    res.json({ ok: true, deleted: true });
  } catch (error) {
    console.error('Error eliminando reserva:', error.message);
    
    // Enviar el mensaje de error específico al frontend
    const statusCode = error.status || 500;
    res.status(statusCode).json({ 
      ok: false,
      error: error.message || 'Error eliminando reserva' 
    });
  }
};
