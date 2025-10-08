import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 3, // Reducido para plan gratuito de Clever Cloud (max 5)
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  idleTimeout: 60000, // Cerrar conexiones inactivas después de 60 segundos
  maxIdle: 2, // Máximo de conexiones inactivas
});

export const getConnection = () => pool.getConnection();
export const query = (sql, params) => pool.query(sql, params);
