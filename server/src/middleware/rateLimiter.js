/**
 * Rate Limiter Middleware para Aquatour CRM
 * Limita el número de peticiones por IP para prevenir ataques de fuerza bruta y DDoS
 */

// Almacenamiento en memoria de intentos por IP
const requestCounts = new Map();
const loginAttempts = new Map();

/**
 * Limpia registros antiguos cada 10 minutos
 */
setInterval(() => {
  const now = Date.now();
  const tenMinutesAgo = now - 10 * 60 * 1000;

  // Limpiar requestCounts
  for (const [ip, data] of requestCounts.entries()) {
    if (data.resetTime < now) {
      requestCounts.delete(ip);
    }
  }

  // Limpiar loginAttempts
  for (const [ip, data] of loginAttempts.entries()) {
    if (data.resetTime < tenMinutesAgo) {
      loginAttempts.delete(ip);
    }
  }
}, 10 * 60 * 1000);

/**
 * Rate limiter general para todas las peticiones
 * @param {number} maxRequests - Máximo de peticiones permitidas
 * @param {number} windowMs - Ventana de tiempo en milisegundos
 */
export const rateLimiter = (maxRequests = 100, windowMs = 60000) => {
  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();

    if (!requestCounts.has(ip)) {
      requestCounts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
      });
      return next();
    }

    const requestData = requestCounts.get(ip);

    // Si la ventana de tiempo expiró, resetear
    if (now > requestData.resetTime) {
      requestCounts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
      });
      return next();
    }

    // Incrementar contador
    requestData.count++;

    // Si excede el límite, rechazar
    if (requestData.count > maxRequests) {
      console.warn(`⚠️ Rate limit excedido para IP: ${ip}`);
      return res.status(429).json({
        error: 'Demasiadas peticiones. Por favor, intenta más tarde.',
        retryAfter: Math.ceil((requestData.resetTime - now) / 1000),
      });
    }

    next();
  };
};

/**
 * Rate limiter específico para login
 * Más estricto para prevenir ataques de fuerza bruta
 * @param {number} maxAttempts - Máximo de intentos de login
 * @param {number} windowMs - Ventana de tiempo en milisegundos
 */
export const loginRateLimiter = (maxAttempts = 5, windowMs = 15 * 60 * 1000) => {
  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();

    if (!loginAttempts.has(ip)) {
      loginAttempts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
        firstAttempt: now,
      });
      return next();
    }

    const attemptData = loginAttempts.get(ip);

    // Si la ventana de tiempo expiró, resetear
    if (now > attemptData.resetTime) {
      loginAttempts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
        firstAttempt: now,
      });
      return next();
    }

    // Incrementar contador
    attemptData.count++;

    // Si excede el límite, bloquear
    if (attemptData.count > maxAttempts) {
      const remainingTime = Math.ceil((attemptData.resetTime - now) / 1000 / 60);
      console.warn(`🚫 Intentos de login excedidos para IP: ${ip} (${attemptData.count} intentos)`);
      
      return res.status(429).json({
        error: `Demasiados intentos de inicio de sesión. Cuenta bloqueada temporalmente.`,
        message: `Por favor, intenta de nuevo en ${remainingTime} minuto(s).`,
        retryAfter: Math.ceil((attemptData.resetTime - now) / 1000),
      });
    }

    // Advertir si está cerca del límite
    if (attemptData.count >= maxAttempts - 1) {
      console.warn(`⚠️ IP ${ip} cerca del límite de login (${attemptData.count}/${maxAttempts})`);
    }

    next();
  };
};

/**
 * Resetea los intentos de login para una IP (llamar después de login exitoso)
 */
export const resetLoginAttempts = (req) => {
  const ip = req.ip || req.connection.remoteAddress;
  if (loginAttempts.has(ip)) {
    loginAttempts.delete(ip);
    console.log(`✅ Intentos de login reseteados para IP: ${ip}`);
  }
};

/**
 * Rate limiter para creación de recursos
 * Previene spam de creación de registros
 */
export const createResourceLimiter = (maxCreations = 20, windowMs = 60000) => {
  const creationCounts = new Map();

  // Limpiar cada 5 minutos
  setInterval(() => {
    const now = Date.now();
    for (const [ip, data] of creationCounts.entries()) {
      if (data.resetTime < now) {
        creationCounts.delete(ip);
      }
    }
  }, 5 * 60 * 1000);

  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();

    if (!creationCounts.has(ip)) {
      creationCounts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
      });
      return next();
    }

    const creationData = creationCounts.get(ip);

    if (now > creationData.resetTime) {
      creationCounts.set(ip, {
        count: 1,
        resetTime: now + windowMs,
      });
      return next();
    }

    creationData.count++;

    if (creationData.count > maxCreations) {
      console.warn(`⚠️ Límite de creación excedido para IP: ${ip}`);
      return res.status(429).json({
        error: 'Demasiadas creaciones en poco tiempo. Por favor, espera un momento.',
        retryAfter: Math.ceil((creationData.resetTime - now) / 1000),
      });
    }

    next();
  };
};

export default {
  rateLimiter,
  loginRateLimiter,
  resetLoginAttempts,
  createResourceLimiter,
};
