import { Router } from 'express';
import { login } from '../controllers/auth.controller.js';
import { loginRateLimiter } from '../middleware/rateLimiter.js';

const router = Router();

// Aplicar rate limiter específico para login (5 intentos por 15 minutos)
router.post('/login', loginRateLimiter(5, 15 * 60 * 1000), login);

export default router;
