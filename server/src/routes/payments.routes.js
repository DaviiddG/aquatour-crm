import express from 'express';
import * as paymentsController from '../controllers/payments.controller.js';

const router = express.Router();

router.get('/', paymentsController.getAllPayments);
router.get('/:id', paymentsController.getPaymentById);
router.get('/reservation/:reservationId', paymentsController.getPaymentsByReservation);
router.get('/quote/:quoteId', paymentsController.getPaymentsByQuote);
router.get('/employee/:employeeId', paymentsController.getPaymentsByEmployee);
router.post('/', paymentsController.createPayment);
router.put('/:id', paymentsController.updatePayment);
router.delete('/:id', paymentsController.deletePayment);

export default router;
