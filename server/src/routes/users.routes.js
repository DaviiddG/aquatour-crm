import { Router } from 'express';
import {
  getUsers,
  getUserById,
  createUserController,
  updateUserController,
  deleteUserController,
  checkEmail,
  checkDocument,
  checkPhone,
} from '../controllers/users.controller.js';

const router = Router();

router.get('/', getUsers);
router.get('/check-email/:email', checkEmail);
router.get('/check-document/:numDocumento', checkDocument);
router.get('/check-phone/:telefono', checkPhone);
router.get('/:idUsuario', getUserById);
router.post('/', createUserController);
router.put('/:idUsuario', updateUserController);
router.delete('/:idUsuario', deleteUserController);

export default router;
