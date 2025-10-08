import express from 'express';
import * as providersController from '../controllers/providers.controller.js';

const router = express.Router();

router.get('/', providersController.getAllProviders);
router.get('/:id', providersController.getProviderById);
router.post('/', providersController.createProvider);
router.put('/:id', providersController.updateProvider);
router.delete('/:id', providersController.deleteProvider);

export default router;
