import { Router } from 'express';
import {
  getReservations,
  getReservationById,
  getReservationsByEmployee,
  createReservationController,
  updateReservationController,
  deleteReservationController,
} from '../controllers/reservations.controller.js';

const router = Router();

router.get('/', getReservations);
router.get('/:idReserva', getReservationById);
router.get('/employee/:idEmpleado', getReservationsByEmployee);
router.post('/', createReservationController);
router.put('/:idReserva', updateReservationController);
router.delete('/:idReserva', deleteReservationController);

export default router;
