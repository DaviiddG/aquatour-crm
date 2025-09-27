import { Router } from 'express';
import {
  getUsers,
  getUserById,
  createUserController,
  updateUserController,
  deleteUserController,
  checkEmail,
} from '../controllers/users.controller.js';

const router = Router();

router.get('/', getUsers);
router.get('/check-email/:email', checkEmail);
router.get('/:idUsuario', getUserById);
router.post('/', createUserController);
router.put('/:idUsuario', updateUserController);
router.delete('/:idUsuario', deleteUserController);

export default router;
