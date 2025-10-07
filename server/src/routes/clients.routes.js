import { Router } from 'express';
import {
  getClients,
  getClientById,
  getClientsByUser,
  createClientController,
  updateClientController,
  deleteClientController,
} from '../controllers/clients.controller.js';

const router = Router();

router.get('/', getClients);
router.get('/user/:idUsuario', getClientsByUser);
router.get('/:idCliente', getClientById);
router.post('/', createClientController);
router.put('/:idCliente', updateClientController);
router.delete('/:idCliente', deleteClientController);

export default router;
