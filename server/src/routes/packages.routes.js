import express from 'express';
import * as packagesController from '../controllers/packages.controller.js';

const router = express.Router();

router.get('/', packagesController.getAllPackages);
router.get('/:id', packagesController.getPackageById);
router.post('/', packagesController.createPackage);
router.put('/:id', packagesController.updatePackage);
router.delete('/:id', packagesController.deletePackage);

export default router;
