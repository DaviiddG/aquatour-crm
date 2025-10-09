import * as packagesService from '../services/packages.service.js';

export const getAllPackages = async (req, res) => {
  try {
    const packages = await packagesService.findAllPackages();
    res.json(packages);
  } catch (error) {
    console.error('Error obteniendo paquetes:', error);
    res.status(500).json({ error: 'Error obteniendo paquetes' });
  }
};

export const getPackageById = async (req, res) => {
  try {
    const package_ = await packagesService.findPackageById(req.params.id);
    if (!package_) {
      return res.status(404).json({ error: 'Paquete no encontrado' });
    }
    res.json(package_);
  } catch (error) {
    console.error('Error obteniendo paquete:', error);
    res.status(500).json({ error: 'Error obteniendo paquete' });
  }
};

export const createPackage = async (req, res) => {
  try {
    const package_ = await packagesService.createPackage(req.body);
    res.status(201).json(package_);
  } catch (error) {
    console.error('Error creando paquete:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error creando paquete' });
  }
};

export const updatePackage = async (req, res) => {
  try {
    const package_ = await packagesService.updatePackage(req.params.id, req.body);
    if (!package_) {
      return res.status(404).json({ error: 'Paquete no encontrado' });
    }
    res.json(package_);
  } catch (error) {
    console.error('Error actualizando paquete:', error);
    res.status(error.status || 500).json({ error: error.message || 'Error actualizando paquete' });
  }
};

export const deletePackage = async (req, res) => {
  try {
    await packagesService.deletePackage(req.params.id);
    res.status(204).send();
  } catch (error) {
    console.error('Error eliminando paquete:', error.message);
    
    // Enviar el mensaje de error específico al frontend
    const statusCode = error.status || 500;
    res.status(statusCode).json({ 
      error: error.message || 'Error eliminando paquete' 
    });
  }
};
