import * as quotesService from '../services/quotes.service.js';

export const getAllQuotes = async (req, res) => {
  try {
    const quotes = await quotesService.findAllQuotes();
    res.json(quotes);
  } catch (error) {
    console.error('Error obteniendo cotizaciones:', error);
    res.status(500).json({ error: 'Error obteniendo cotizaciones' });
  }
};

export const getQuotesByEmployee = async (req, res) => {
  try {
    const quotes = await quotesService.findQuotesByEmployee(req.params.employeeId);
    res.json(quotes);
  } catch (error) {
    console.error('Error obteniendo cotizaciones del empleado:', error);
    res.status(500).json({ error: 'Error obteniendo cotizaciones' });
  }
};

export const getQuoteById = async (req, res) => {
  try {
    const quote = await quotesService.findQuoteById(req.params.id);
    if (!quote) {
      return res.status(404).json({ error: 'Cotización no encontrada' });
    }
    res.json(quote);
  } catch (error) {
    console.error('Error obteniendo cotización:', error);
    res.status(500).json({ error: 'Error obteniendo cotización' });
  }
};

export const createQuote = async (req, res) => {
  try {
    const quote = await quotesService.createQuote(req.body);
    res.status(201).json(quote);
  } catch (error) {
    console.error('Error creando cotización:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error creando cotización' });
  }
};

export const updateQuote = async (req, res) => {
  try {
    const quote = await quotesService.updateQuote(req.params.id, req.body);
    if (!quote) {
      return res.status(404).json({ error: 'Cotización no encontrada' });
    }
    res.json(quote);
  } catch (error) {
    console.error('Error actualizando cotización:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error actualizando cotización' });
  }
};

export const deleteQuote = async (req, res) => {
  try {
    const deleted = await quotesService.deleteQuote(req.params.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Cotización no encontrada' });
    }
    res.status(204).send();
  } catch (error) {
    console.error('Error eliminando cotización:', error);
    res.status(500).json({ error: 'Error eliminando cotización' });
  }
};
