import { verifyPassword } from '../services/password.service.js';
import { findByEmail } from '../services/users.service.js';
import { resetLoginAttempts } from '../middleware/rateLimiter.js';

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const ip = req.ip || req.connection.remoteAddress;

    if (!email || !password) {
      console.warn(`⚠️ Intento de login sin credenciales desde IP: ${ip}`);
      return res.status(400).json({
        ok: false,
        error: 'Email y contraseña son obligatorios',
      });
    }

    const userRecord = await findByEmail(email);

    if (!userRecord) {
      console.warn(`⚠️ Intento de login con email inexistente: ${email} desde IP: ${ip}`);
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    if (!userRecord.activo) {
      console.warn(`⚠️ Intento de login con usuario inactivo: ${email} desde IP: ${ip}`);
      return res.status(403).json({
        ok: false,
        error: 'Usuario inactivo',
      });
    }

    const isValidPassword = await verifyPassword(password, userRecord.contrasena);

    if (!isValidPassword) {
      console.warn(`⚠️ Intento de login con contraseña incorrecta: ${email} desde IP: ${ip}`);
      return res.status(401).json({
        ok: false,
        error: 'Credenciales incorrectas',
      });
    }

    // Login exitoso - resetear intentos de login
    resetLoginAttempts(req);
    
    const { contrasena, ...user } = userRecord;

    console.log(`✅ Login exitoso: ${email} (${user.rol}) desde IP: ${ip}`);

    res.json({
      ok: true,
      user,
    });
  } catch (error) {
    next(error);
  }
};
