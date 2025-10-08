import * as providersService from '../services/providers.service.js';

export const getAllProviders = async (req, res) => {
  try {
    const providers = await providersService.findAllProviders();
    res.json(providers);
  } catch (error) {
    console.error('Error obteniendo proveedores:', error);
    res.status(500).json({ error: 'Error obteniendo proveedores' });
  }
};

export const getProviderById = async (req, res) => {
  try {
    const provider = await providersService.findProviderById(req.params.id);
    if (!provider) {
      return res.status(404).json({ error: 'Proveedor no encontrado' });
    }
    res.json(provider);
  } catch (error) {
    console.error('Error obteniendo proveedor:', error);
    res.status(500).json({ error: 'Error obteniendo proveedor' });
  }
};

export const createProvider = async (req, res) => {
  try {
    const provider = await providersService.createProvider(req.body);
    res.status(201).json(provider);
  } catch (error) {
    console.error('Error creando proveedor:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error creando proveedor' });
  }
};

export const updateProvider = async (req, res) => {
  try {
    const provider = await providersService.updateProvider(req.params.id, req.body);
    if (!provider) {
      return res.status(404).json({ error: 'Proveedor no encontrado' });
    }
    res.json(provider);
  } catch (error) {
    console.error('Error actualizando proveedor:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error actualizando proveedor' });
  }
};

export const deleteProvider = async (req, res) => {
  try {
    const deleted = await providersService.deleteProvider(req.params.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Proveedor no encontrado' });
    }
    res.status(204).send();
  } catch (error) {
    console.error('Error eliminando proveedor:', error);
    res.status(500).json({ error: 'Error eliminando proveedor' });
  }
};
