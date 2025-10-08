import express from 'express';
import * as quotesController from '../controllers/quotes.controller.js';

const router = express.Router();

router.get('/', quotesController.getAllQuotes);
router.get('/employee/:employeeId', quotesController.getQuotesByEmployee);
router.get('/:id', quotesController.getQuoteById);
router.post('/', quotesController.createQuote);
router.put('/:id', quotesController.updateQuote);
router.delete('/:id', quotesController.deleteQuote);

export default router;
