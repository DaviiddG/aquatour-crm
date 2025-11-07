import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/users.routes.js';
import clientRoutes from './routes/clients.routes.js';
import contactRoutes from './routes/contacts.routes.js';
import destinationRoutes from './routes/destinations.routes.js';
import reservationRoutes from './routes/reservations.routes.js';
import paymentRoutes from './routes/payments.routes.js';
import packageRoutes from './routes/packages.routes.js';
import quoteRoutes from './routes/quotes.routes.js';
import providerRoutes from './routes/providers.routes.js';
import auditRoutes from './routes/audit.routes.js';
import accessLogRoutes from './routes/access-log.routes.js';
import systemRoutes from './routes/system.routes.js';
import { errorHandler } from './utils/error-handler.js';

dotenv.config();

const app = express();

app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/destinations', destinationRoutes);
app.use('/api/reservations', reservationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/api/providers', providerRoutes);
app.use('/api/audit-logs', auditRoutes);
app.use('/api/access-logs', accessLogRoutes);
app.use('/api/system', systemRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Aquatour backend running on port ${PORT}`);
});
