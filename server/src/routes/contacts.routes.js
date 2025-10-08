import { Router } from 'express';
import {
  getContacts,
  getContactById,
  createContactController,
  updateContactController,
  deleteContactController,
} from '../controllers/contacts.controller.js';

const router = Router();

router.get('/', getContacts);
router.get('/:idContacto', getContactById);
router.post('/', createContactController);
router.put('/:idContacto', updateContactController);
router.delete('/:idContacto', deleteContactController);

export default router;
