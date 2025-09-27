import { verifyPassword } from '../services/password.service.js';
import { findByEmail } from '../services/users.service.js';

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        error: 'Email y contraseña son obligatorios',
      });
    }

    const userRecord = await findByEmail(email);

    if (!userRecord) {
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    if (!userRecord.activo) {
      return res.status(403).json({
        ok: false,
        error: 'Usuario inactivo',
      });
    }

    const isValidPassword = await verifyPassword(password, userRecord.contrasena);

    if (!isValidPassword) {
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    const { contrasena, ...user } = userRecord;

    res.json({
      ok: true,
      user,
    });
  } catch (error) {
    next(error);
  }
};
