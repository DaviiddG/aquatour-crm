import * as paymentsService from '../services/payments.service.js';

export const getAllPayments = async (req, res) => {
  try {
    const payments = await paymentsService.findAllPayments();
    res.json(payments);
  } catch (error) {
    console.error('Error obteniendo pagos:', error);
    res.status(500).json({ error: 'Error obteniendo pagos' });
  }
};

export const getPaymentById = async (req, res) => {
  try {
    const payment = await paymentsService.findPaymentById(req.params.id);
    if (!payment) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }
    res.json(payment);
  } catch (error) {
    console.error('Error obteniendo pago:', error);
    res.status(500).json({ error: 'Error obteniendo pago' });
  }
};

export const getPaymentsByReservation = async (req, res) => {
  try {
    const payments = await paymentsService.findPaymentsByReservation(req.params.reservationId);
    res.json(payments);
  } catch (error) {
    console.error('Error obteniendo pagos de reserva:', error);
    res.status(500).json({ error: 'Error obteniendo pagos de reserva' });
  }
};

export const getPaymentsByEmployee = async (req, res) => {
  try {
    const payments = await paymentsService.findPaymentsByEmployee(req.params.employeeId);
    res.json(payments);
  } catch (error) {
    console.error('Error obteniendo pagos de empleado:', error);
    res.status(500).json({ error: 'Error obteniendo pagos de empleado' });
  }
};

export const createPayment = async (req, res) => {
  try {
    const payment = await paymentsService.createPayment(req.body);
    res.status(201).json(payment);
  } catch (error) {
    console.error('Error creando pago:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error creando pago' });
  }
};

export const updatePayment = async (req, res) => {
  try {
    const payment = await paymentsService.updatePayment(req.params.id, req.body);
    if (!payment) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }
    res.json(payment);
  } catch (error) {
    console.error('Error actualizando pago:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error actualizando pago' });
  }
};

export const deletePayment = async (req, res) => {
  try {
    const deleted = await paymentsService.deletePayment(req.params.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }
    res.status(204).send();
  } catch (error) {
    console.error('Error eliminando pago:', error);
    res.status(500).json({ error: 'Error eliminando pago' });
  }
};
