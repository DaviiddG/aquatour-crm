import { Router } from 'express';
import {
  getDestinations,
  getDestinationById,
  createDestinationController,
  updateDestinationController,
  deleteDestinationController,
} from '../controllers/destinations.controller.js';

const router = Router();

router.get('/', getDestinations);
router.get('/:idDestino', getDestinationById);
router.post('/', createDestinationController);
router.put('/:idDestino', updateDestinationController);
router.delete('/:idDestino', deleteDestinationController);

export default router;
